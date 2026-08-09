//
//  FetchHomeRecommendationsUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 7/21/26.
//

import Foundation
import RxSwift
import OSLog

// 기존 FetchHomeProgramRecommendationsUseCase
final class FetchHomeRecommendationsUseCase {
    private struct ProgramCandidate {
        let program: Program
        let facility: Facility
        let distance: Double
    }
    
    private let dateService: DateService
    private let sportsRepository: SportsRepositoryProtocol
    private let recommendationRuleRepository: SportRecommendationRuleRepositoryProtocol
    
    init(
        dateService: DateService,
        sportsRepository: SportsRepositoryProtocol,
        recommendationRuleRepository: SportRecommendationRuleRepositoryProtocol
    ) {
        self.dateService = dateService
        self.sportsRepository = sportsRepository
        self.recommendationRuleRepository = recommendationRuleRepository
    }
    
    func fetchSportsRecommendation(profile: UserProfile?) -> Single<[RecommendedSports]> {
        guard let profile else { return .just([])}
        
        let ageGroup = ageGroup(for: profile.birthDate)
        
        return recommendationRuleRepository.fetchActiveRules()
            .map { rules in
                rules.map { rule in
                    do {
                        let ruleScore = try ProgramMatchRateCalculator.ruleScore(
                            profile: profile,
                            rule: rule,
                            ageGroup: ageGroup,
                            includesBodyPart: true
                        )
                        
                        let matchRate = ProgramMatchRateCalculator.matchRate(
                            ruleScore: ruleScore,
                            sportsCategory: rule.sportsCategory,
                            preferred: profile.preferredSportsCategories
                        )
                        
                        return RecommendedSports(
                            sportsName: rule.sportsName,
                            sportsCategory: rule.sportsCategory,
                            matchRate: matchRate
                        )
                    } catch {
                        // 에러 로그
                    }
                }
                .sorted {
                    // 매칭률이 높은 순 정렬
                    if $0.matchRate == $1.matchRate {
                        // 동일할 시 이름 순 정렬
                        return $0.sportsName < $1.sportsName
                    }
                    
                    return $0.matchRate > $1.matchRate
                }
            }
    }
    
    func fetchProgramRecommendation(profile: UserProfile?, location: UserLocation?) -> Single<[HomeRecommendedProgram]> {
        guard let profile,
              let latitude = location?.latitude,
              let longitude = location?.longitude else {
            return .just([])
        }
        
        let coordinate = GeoCoordinate(latitude: latitude, longitude: longitude)
        let ageGroup = ageGroup(for: profile.birthDate)
        
        return fetchCandidates(coordinate: coordinate) // 위치 기반 프로그램 가져오기
            .flatMap { [recommendationRuleRepository] candidates -> Single<[HomeRecommendedProgram]> in
                // 추천 후보 프로그램 종목명 모음
                let candidateSportsNames = Set(candidates.compactMap { candidate in
                    candidate.program.sport?.replacingOccurrences(of: " ", with: "")
                })
                
                // 추천 규칙(rule)에 기반한 점수 구하기
                return recommendationRuleRepository.fetchActiveRules()
                    .map { rules in
                        // 추천 프로그램 후보에 해당하는 종목 rule만 필터링
                        let relevantRules = rules.filter { rule in
                            let sportsName = rule.sportsName.replacingOccurrences(of: " ", with: "")
                            return candidateSportsNames.contains(sportsName)
                        }
                        
                        let programRecommendationRuleScores = try relevantRules.reduce(into: [String: Int]()) { result, rule in
                            let sportsName = rule.sportsName.replacingOccurrences(of: " ", with: "")
                            
                            result[sportsName] = try ProgramMatchRateCalculator.ruleScore(
                                profile: profile,
                                rule: rule,
                                ageGroup: ageGroup,
                                includesBodyPart: false
                            )
                        }
                        
                        let recommendations = candidates.compactMap { candidate -> HomeRecommendedProgram? in
                            guard let sportsName = candidate.program.sport?.replacingOccurrences(of: " ", with: ""),
                                  let ruleScore = programRecommendationRuleScores[sportsName] else {
                                return nil
                            }
                            
                            let matchRate = ProgramMatchRateCalculator.matchRate(
                                ruleScore: ruleScore,
                                sportsCategory: candidate.program.sportsCategory,
                                preferred: profile.preferredSportsCategories
                            )
                            
                            return HomeRecommendedProgram(
                                program: candidate.program,
                                facility: candidate.facility,
                                matchRate: matchRate,
                                distance: candidate.distance
                            )
                        }
                            .sorted(by: { // 매칭률 높은 순, 동일하다면 거리가 가까운 순
                                if $0.matchRate == $1.matchRate {
                                    return $0.distance < $1.distance
                                }
                                
                                return $0.matchRate > $1.matchRate
                            })
                        
                        return Array(recommendations.prefix(6))
                    }
            }
    }
    
    //        func fetchRecommendedProgram(profile: UserProfile?, location: UserLocation?) -> Single<[HomeRecommendedProgram]> {
    //            guard let profile,
    //                  let latitude = location?.latitude,
    //                  let longitude = location?.longitude else {
    //                return .just([])
    //            }
    //
    //            let coordinate = GeoCoordinate(latitude: latitude, longitude: longitude)
    //            let ageGroup = ageGroup(for: profile.birthDate)
    //
    //            return fetchCandidates(coordinate: coordinate) // 위치 기반 프로그램 가져오기
    //                .flatMap { [recommendationRuleRepository] candidates -> Single<[HomeRecommendedProgram]> in
    //                    // 추천 후보 프로그램 종목명 모음
    //                    let candidateSportsNames = Set(candidates.compactMap { candidate in
    //                        candidate.program.sport?.replacingOccurrences(of: " ", with: "")
    //                    })
    //
    //                    // 추천 규칙(rule)에 기반한 점수 구하기
    //                    return recommendationRuleRepository.fetchActiveRules()
    //                        .map { rules in
    //                            // 추천 프로그램 후보에 해당하는 종목 rule만 필터링
    //                            let relevantRules = rules.filter { rule in
    //                                let sportsName = rule.sportsName.replacingOccurrences(of: " ", with: "")
    //                                return candidateSportsNames.contains(sportsName)
    //                            }
    //
    //                            let programRecommendationRuleScores = try relevantRules.reduce(into: [String: Int]()) { result, rule in
    //                                let sportsName = rule.sportsName.replacingOccurrences(of: " ", with: "")
    //
    //                                result[sportsName] = try ProgramMatchRateCalculator.ruleScore(
    //                                    profile: profile,
    //                                    rule: rule,
    //                                    ageGroup: ageGroup,
    //                                    includesBodyPart: false
    //                                )
    //                            }
    //
    //                            let sportsRecommendationRuleScores = try relevantRules.reduce(into: [String: Int]()) { result, rule in
    //                                let sportsName = rule.sportsName.replacingOccurrences(of: " ", with: "")
    //
    //                                result[sportsName] = try ProgramMatchRateCalculator.ruleScore(
    //                                    profile: profile,
    //                                    rule: rule,
    //                                    ageGroup: ageGroup,
    //                                    includesBodyPart: true
    //                                )
    //                            }
    //
    //                            return Self.recommendedPrograms(
    //                                from: candidates,
    //                                profile: profile,
    //                                categorySports: ruleScoresWithoutBodyParts,
    //                                personalizedSports: ruleScoresWithBodyParts
    //                            )
    //                        }
    //                }
    //        }
}

private extension FetchHomeRecommendationsUseCase {
    static let defaultLocationAddress = "서울 종로구 효자로 12 국립고궁박물관"
    static let defaultLocationLatitude = 37.57665
    static let defaultLocationLongitude = 126.97498
    static let primaryRadiusMeters = 5_000.0
    static let expandedRadiusMeters = 20_000.0
    static let facilitySearchLimit = 2_000
    static let programFetchLimit = 1_000
    static let programFacilityChunkSize = 100
    static let nearbyProgramLimit = 8
    static let recommendedProgramLimit = 6
    
    private func fetchCandidates(coordinate: GeoCoordinate, radiusMeters: Double) -> Single<[ProgramCandidate]> {
        fetchNearbyFacilities(coordinate: coordinate, radiusMeters: radiusMeters)
            .flatMap { [sportsRepository] facilities -> Single<[ProgramCandidate]> in
                guard !facilities.isEmpty else {
                    return .just([])
                }
                
                // 중복 시설 제거
                let facilitiesByID = Dictionary(
                    facilities.compactMap { facility in
                        facility.id.map { ($0, facility) }
                    },
                    uniquingKeysWith: { first, _ in first }
                )
                let chunks = Array(facilitiesByID.keys).chunked(into: Self.programFacilityChunkSize)
                
                return Observable.from(chunks)
                    .concatMap { chunk in
                        sportsRepository.fetchPrograms(
                            facilityIDs: chunk,
                            limit: Self.programFetchLimit,
                            offset: 0,
                            order: .ascending
                        )
                        .asObservable()
                    }
                    .toArray()
                    .map { pages in
                        Self.programCandidates(
                            from: pages.flatMap(\.items),
                            facilitiesByID: facilitiesByID,
                            coordinate: coordinate
                        )
                    }
            }
    }
    
    private func fetchCandidates(coordinate: GeoCoordinate) -> Single<[ProgramCandidate]> {
        // 처음 5km 반경 내에서 후보 추리기
        fetchCandidates(coordinate: coordinate, radiusMeters: Self.primaryRadiusMeters)
            .flatMap { [weak self] result -> Single<[ProgramCandidate]> in
                guard let self else { return .just(result) }
                guard result.isEmpty else { return .just(result) }
                
                // 후보가 없으면 반경을 넓혀서(20km) 다시 추림
                return self.fetchCandidates(
                    coordinate: coordinate,
                    radiusMeters: Self.expandedRadiusMeters
                )
            }
    }
    
    private func fetchNearbyFacilities(coordinate: GeoCoordinate, radiusMeters: Double) -> Single<[Facility]> {
        let bounds = coordinate.bounds(radiusMeters: radiusMeters)
        
        return sportsRepository.fetchFacilities(
            latitudeRange: bounds.latitude,
            longitudeRange: bounds.longitude,
            limit: Self.facilitySearchLimit,
            offset: 0,
            order: .ascending
        )
        .map { page in
            page.items
                .filter {
                    coordinate.distance(to: $0.coordinate) <= radiusMeters
                }
                .sorted {
                    coordinate.distance(to: $0.coordinate) < coordinate.distance(to: $1.coordinate)
                }
        }
    }
    
    private static func programCandidates(
        from programs: [Program],
        facilitiesByID: [String: Facility],
        coordinate: GeoCoordinate
    ) -> [ProgramCandidate] {
        programs.compactMap { program in
            guard let facilityID = program.publicFacilityID,
                  let facility = facilitiesByID[facilityID] else {
                return nil
            }
            
            return ProgramCandidate(
                program: program,
                facility: facility,
                distance: coordinate.distance(to: facility.coordinate)
            )
        }
    }
    
    // 주변 프로그램 반환 (고려 조건: 거리)
    private static func nearbyPrograms(from candidates: [ProgramCandidate]) -> [HomeRecommendedProgram] {
        candidates
            .sorted {
                if $0.distance == $1.distance {
                    return ($0.program.id ?? 0) < ($1.program.id ?? 0)
                }
                
                return $0.distance < $1.distance
            }
            .prefix(nearbyProgramLimit)
            .map {
                HomeRecommendedProgram(
                    program: $0.program,
                    facility: $0.facility,
                    matchRate: 0,
                    distance: 0
                )
            }
    }
}
// 기존 RecommendSportsUseCase
extension FetchHomeRecommendationsUseCase {
    func execute(profile: UserProfile) -> Single<[RecommendedSports]> {
        executePersonalizedScores(profile: profile)
            .map(Self.visibleRecommendations)
    }
    
}

private extension FetchHomeRecommendationsUseCase {
    static let primaryThreshold = 70
    static let fallbackThreshold = 60
    static let minimumRecommendationCount = 3
    static let maximumVisibleRecommendationCount = 8
    static let preferredCategoryBonus = 5
    
    static func visibleRecommendations(from scoredSports: [RecommendedSports]) -> [RecommendedSports] {
        var recommendations = scoredSports.filter { $0.matchRate >= primaryThreshold }
        if recommendations.count < minimumRecommendationCount {
            recommendations = scoredSports.filter { $0.matchRate >= fallbackThreshold }
        }
        
        return Array(recommendations.prefix(maximumVisibleRecommendationCount))
    }
    
    func ageGroup(for birthDate: Date) -> String {
        let age = dateService.age(of: birthDate)
        
        switch age {
        case ..<7:
            return "아이"
        case 7..<13:
            return "어린이"
        case 13..<20:
            return "청소년"
        case 20..<30:
            return "20대"
        case 30..<40:
            return "30대"
        case 40..<50:
            return "40대"
        case 50..<60:
            return "50대"
        default:
            return "60대 이상"
        }
    }
}

// 기존 GenerateHomeRecommendationCopyUseCase
extension FetchHomeRecommendationsUseCase {
    private let repository: HomeRecommendationCopyRepositoryProtocol
    private let calendar: Calendar
    
    init(
        repository: HomeRecommendationCopyRepositoryProtocol,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }
    
    func execute(
        profile: UserProfile,
        recommendedSports: [RecommendedSports]
    ) -> Single<HomeRecommendationCopy> {
        repository.generateCopy(
            profile: profile,
            recommendedSports: recommendedSports,
            ageGroup: Self.ageGroup(for: profile.birthDate, calendar: calendar)
        )
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

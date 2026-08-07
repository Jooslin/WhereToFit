//
//  FetchHomeRecommendationsUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 7/21/26.
//

import Foundation
import RxSwift

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
    
    func fetchRecommendedProgram(profile: UserProfile?, location: UserLocation?) -> Single<[HomeRecommendedProgram]> {
        guard let profile,
              let latitude = location?.latitude,
              let longitude = location?.longitude else {
            return .just([])
        }
        
        let coordinate = GeoCoordinate(latitude: latitude, longitude: longitude)
        let ageGroup = ageGroup(for: profile.birthDate)
        
        return fetchCandidates(coordinate: coordinate) // 위치 기반 프로그램 가져오기
            .flatMap { [recommendationRuleRepository] candidates -> Single<[HomeRecommendedProgram]> in
//                guard let self else {
//                    return .just(Self.nearbyPrograms(from: candidates))
//                }
                
                // 추천 규칙(rule)에 기반한 점수 구하기
                recommendationRuleRepository.fetchActiveRules()
                    .map { rules in
                        let rulesBySportName = Dictionary(
                            uniqueKeysWithValues: rules.map { rule in
                                let key = rule.sportName.replacingOccurrences(of: " ", with: "")
                                return (key, rule)
                            })
                        
                        // 추천 프로그램 후보에 해당하는 종목 rule만 필터링
                        let relevantRules = rulesBySportName.filter { rule in
                            candidates.contains(where: { candidate in
                                candidate.program.sport == rule.key
                            })
                            
                        }
                        
                    }
                return Single.zip(
                    self.executeRuleScores(profile: profile, isPersonalized: true),
                    self.executeRuleScores(profile: profile, isPersonalized: false)
                )
                .map { categorySports, personalizedSports in
                    Self.recommendedPrograms(
                        from: candidates,
                        profile: profile,
                        categorySports: categorySports,
                        personalizedSports: personalizedSports
                    )
                }
            }
    }
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
                    matchRate: nil
                )
            }
    }
    
    private static func recommendedPrograms(
        from candidates: [ProgramCandidate],
        profile: UserProfile,
        categorySports: [RecommendedSport],
        personalizedSports: [RecommendedSport]
    ) -> [HomeRecommendedProgram] {
        let matchRateContext = ProgramMatchRateCalculator.Context(
            profile: profile,
            categorySports: categorySports,
            personalizedSports: personalizedSports
        )
        
        return candidates
            .compactMap { candidate -> (candidate: ProgramCandidate, finalScore: Double, matchRate: Int)? in
                guard let programScore = ProgramMatchRateCalculator.programScore(
                    for: candidate.program,
                    context: matchRateContext
                ) else {
                    return nil
                }
                
                return (
                    candidate,
                    finalSelectionScore(
                        sportScore: programScore.selectionSportScore,
                        levelScore: programScore.levelScore,
                        distance: candidate.distance
                    ),
                    programScore.matchRate
                )
            }
            .sorted {
                if $0.finalScore == $1.finalScore {
                    return $0.candidate.distance < $1.candidate.distance
                }
                
                return $0.finalScore > $1.finalScore
            }
            .prefix(recommendedProgramLimit)
            .map {
                HomeRecommendedProgram(
                    program: $0.candidate.program,
                    facility: $0.candidate.facility,
                    matchRate: $0.matchRate
                )
            }
    }
    
    static func finalSelectionScore(
        sportScore: Int,
        levelScore: Int,
        distance: Double
    ) -> Double {
        let distanceScore: Double
        switch max(distance, 0) {
        case ...3_000:
            distanceScore = 100
        case ...5_000:
            distanceScore = 70
        case ...10_000:
            distanceScore = 40
        case ...20_000:
            distanceScore = 10
        default:
            distanceScore = 0
        }
        
        return Double(sportScore) * 0.35
            + Double(levelScore) * 0.3
            + distanceScore * 0.35
    }
}

// 기존 RecommendSportsUseCase
extension FetchHomeRecommendationsUseCase {
    func execute(profile: UserProfile) -> Single<[RecommendedSport]> {
        executePersonalizedScores(profile: profile)
            .map(Self.visibleRecommendations)
    }
    
    func executeRuleScores(profile: UserProfile, isPersonalized: Bool) -> Single<[RecommendedSport]> {
        let ageGroup = ageGroup(for: profile.birthDate)
        
        return recommendationRuleRepository.fetchActiveRules()
            .map { rules in
                Self.scoredSports(
                    profile: profile,
                    rules: rules,
                    ageGroup: ageGroup,
                    includesPersonalization: isPersonalized
                )
            }
    }
//
//    func executePersonalizedScores(profile: UserProfile) -> Single<[RecommendedSport]> {
//        let ageGroup = ageGroup(for: profile.birthDate)
//        
//        return recommendationRuleRepository.fetchActiveRules()
//            .map { rules in
//                Self.scoredSports(
//                    profile: profile,
//                    rules: rules,
//                    ageGroup: ageGroup,
//                    includesPersonalization: true
//                )
//            }
//    }
//    
//    func executeCategory(profile: UserProfile) -> Single<[RecommendedSport]> {
//        let ageGroup = ageGroup(for: profile.birthDate)
//        
//        return recommendationRuleRepository.fetchActiveRules()
//            .map { rules in
//                return Self.scoredSports(
//                    profile: profile,
//                    rules: rules,
//                    ageGroup: ageGroup,
//                    includesPersonalization: false
//                )
//            }
//    }
}

private extension FetchHomeRecommendationsUseCase {
    static let primaryThreshold = 70
    static let fallbackThreshold = 60
    static let minimumRecommendationCount = 3
    static let maximumVisibleRecommendationCount = 8
    static let preferredCategoryBonus = 5
    
    static func scoredSports(
        profile: UserProfile,
        rules: [SportRecommendationRule],
        ageGroup: String,
        includesPersonalization: Bool
    ) -> [RecommendedSport] {
        rules
            .map { rule in
                RecommendedSport(
                    sportName: rule.sportName,
                    sportsCategory: rule.sportsCategory,
                    matchRate: matchRate(
                        profile: profile,
                        rule: rule,
                        ageGroup: ageGroup,
                        includesPersonalization: includesPersonalization
                    )
                )
            }
            .sorted {
                if $0.matchRate == $1.matchRate {
                    return $0.sportName < $1.sportName
                }
                
                return $0.matchRate > $1.matchRate
            }
    }
    
    static func visibleRecommendations(from scoredSports: [RecommendedSport]) -> [RecommendedSport] {
        var recommendations = scoredSports.filter { $0.matchRate >= primaryThreshold }
        if recommendations.count < minimumRecommendationCount {
            recommendations = scoredSports.filter { $0.matchRate >= fallbackThreshold }
        }
        
        return Array(recommendations.prefix(maximumVisibleRecommendationCount))
    }
    
    static func matchRate(
        profile: UserProfile,
        rule: SportRecommendationRule,
        ageGroup: String,
        includesPersonalization: Bool
    ) -> Int {
        let ageScore = rule.ageWeights[ageGroup] ?? 0
        let experienceScore = profile.exerciseExperience
            .map { rule.experienceWeights[$0.rawValue] ?? 0 } ?? 0
        let goalScore = profile.exerciseGoal
            .map { rule.goalWeights[goalKey(for: $0)] ?? 0 } ?? 0
        
        let scores: [Int]
        let bonus: Int
        if includesPersonalization {
            let bodyPartScore = bodyPartSuitabilityScore(
                discomfortBodyParts: profile.discomfortBodyParts,
                riskWeights: rule.bodyPartRiskWeights
            )
            scores = [ageScore, experienceScore, goalScore, bodyPartScore]
            bonus = profile.preferredSportsCategories.contains(rule.sportsCategory)
                ? preferredCategoryBonus
                : 0
        } else {
            scores = [ageScore, experienceScore, goalScore]
            bonus = 0
        }
        
        let baseScore = Double(scores.reduce(0, +)) / Double(scores.count)
        
        return min(100, Int((baseScore + Double(bonus)).rounded()))
    }
    
    static func bodyPartSuitabilityScore(
        discomfortBodyParts: [DiscomfortBodyPart],
        riskWeights: [String: Int]
    ) -> Int {
        guard discomfortBodyParts.isEmpty == false else {
            return 100
        }
        
        let maxRisk = discomfortBodyParts
            .map { riskWeights[$0.rawValue] ?? 0 }
            .max() ?? 0
        
        return max(0, 100 - maxRisk)
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
    
    static func goalKey(for goal: ExerciseGoal) -> String {
        switch goal {
        case .strengthImprovement:
            return "근력향상"
        case .diet:
            return "다이어트"
        case .fitnessImprovement:
            return "체력향상"
        case .postureCorrection:
            return "자세교정"
        case .healthCare:
            return "건강관리"
        case .stressRelief:
            return "스트레스 해소"
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
        recommendedSports: [RecommendedSport]
    ) -> Single<HomeRecommendationCopy> {
        repository.generateCopy(
            profile: profile,
            recommendedSports: recommendedSports,
            ageGroup: Self.ageGroup(for: profile.birthDate, calendar: calendar)
        )
    }
}

private extension GenerateHomeRecommendationCopyUseCase {
    static func ageGroup(for birthDate: Date, calendar: Calendar) -> String {
        let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        
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

// 기존 PreloadSportsRecommendationRulesUseCase
extension FetchHomeRecommendationsUseCase {
    private let repository: SportRecommendationRuleRepositoryProtocol
    
    init(repository: SportRecommendationRuleRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute() -> Single<Void> {
        repository.fetchActiveRules()
            .map { _ in () }
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

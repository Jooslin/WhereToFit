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
//    private struct GeoCoordinate {
//        let address: String
//        let latitude: Double
//        let longitude: Double
//    }
    
    private struct ProgramCandidate {
        let program: Program
        let facility: Facility
        let distance: Double
    }
    
    private struct CandidateResult {
        let candidates: [ProgramCandidate]
        let radiusMeters: Double
    }
    
    private let sportsRepository: SportsRepositoryProtocol
    private let recommendSportsUseCase: RecommendSportsUseCase
    
    init(
        sportsRepository: SportsRepositoryProtocol,
        recommendSportsUseCase: RecommendSportsUseCase
    ) {
        self.sportsRepository = sportsRepository
        self.recommendSportsUseCase = recommendSportsUseCase
    }
    
    func executeProgramRecommendation(profile: UserProfile?, location: UserLocation?) -> Single<[HomeRecommendedProgram]> {
        
    }
    
    func execute(profile: UserProfile?, location: UserLocation?) -> Single<[HomeRecommendedProgram]> {
        guard let latitude = location?.latitude,
              let longitude = location?.longitude else {
            return .just([])
        }
        
        let coordinate = GeoCoordinate(latitude: latitude, longitude: longitude)
        
        return fetchCandidates(context: context, radiusMeters: Self.primaryRadiusMeters)
            .flatMap { [weak self] result -> Single<CandidateResult> in
                guard let self else { return .just(result) }
                guard result.candidates.isEmpty else { return .just(result) }
                
                return self.fetchCandidates(
                    context: context,
                    radiusMeters: Self.expandedRadiusMeters
                )
            }
            .flatMap { [recommendSportsUseCase] result -> Single<[HomeRecommendedProgram]> in
                guard let profile else {
                    return .just(Self.nearbyPrograms(from: result.candidates))
                }
                
                return Single.zip(
                    recommendSportsUseCase.executeCategory(profile: profile),
                    recommendSportsUseCase.executePersonalizedScores(profile: profile)
                )
                .map { categorySports, personalizedSports in
                    Self.recommendedPrograms(
                        from: result.candidates,
                        profile: profile,
                        categorySports: categorySports,
                        personalizedSports: personalizedSports,
                        radiusMeters: result.radiusMeters
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
    
    private static func locationContext(from location: UserLocation?) -> GeoCoordinate {
        GeoCoordinate(
            address: location?.address ?? defaultLocationAddress,
            latitude: location?.latitude ?? defaultLocationLatitude,
            longitude: location?.longitude ?? defaultLocationLongitude
        )
    }
    
    private func fetchCandidates(coordinate: GeoCoordinate, radiusMeters: Double) -> Single<CandidateResult> {
        fetchNearbyFacilities(context: coordinate, radiusMeters: radiusMeters)
            .flatMap { [sportsRepository] facilities -> Single<CandidateResult> in
                guard facilities.isEmpty == false else {
                    return .just(CandidateResult(candidates: [], radiusMeters: radiusMeters))
                }
                
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
                        CandidateResult(
                            candidates: Self.programCandidates(
                                from: pages.flatMap(\.items),
                                facilitiesByID: facilitiesByID,
                                context: coordinate
                            ),
                            radiusMeters: radiusMeters
                        )
                    }
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
                    Self.distance(
                        fromLatitude: context.latitude,
                        fromLongitude: context.longitude,
                        to: $0
                    ) <= radiusMeters
                }
                .sorted {
                    Self.distance(
                        fromLatitude: context.latitude,
                        fromLongitude: context.longitude,
                        to: $0
                    )
                    <
                    Self.distance(
                        fromLatitude: context.latitude,
                        fromLongitude: context.longitude,
                        to: $1
                    )
                }
        }
    }
    
    private static func programCandidates(
        from programs: [Program],
        facilitiesByID: [String: Facility],
        context: GeoCoordinate
    ) -> [ProgramCandidate] {
        programs.compactMap { program in
            guard let facilityID = program.publicFacilityID,
                  let facility = facilitiesByID[facilityID] else {
                return nil
            }
            
            return ProgramCandidate(
                program: program,
                facility: facility,
                distance: distance(
                    fromLatitude: context.latitude,
                    fromLongitude: context.longitude,
                    to: facility
                )
            )
        }
    }
    
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
        personalizedSports: [RecommendedSport],
        radiusMeters: Double
    ) -> [HomeRecommendedProgram] {
        let matchRateContext = ProgramMatchRateCalculator.Context(
            profile: profile,
            categorySports: categorySports,
            personalizedSports: personalizedSports
        )
        
        return candidates
            .compactMap { candidate -> (candidate: ProgramCandidate, finalScore: Int, matchRate: Int)? in
                guard let programScore = ProgramMatchRateCalculator.programScore(
                    for: candidate.program,
                    context: matchRateContext
                ) else {
                    return nil
                }
                
                return (
                    candidate,
                    finalSelectionScore(
                        selectionScore: programScore.selectionScore,
                        distance: candidate.distance,
                        radiusMeters: radiusMeters
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
    
    static func coordinateBounds(
        latitude: Double,
        longitude: Double,
        radiusMeters: Double
    ) -> (latitude: ClosedRange<Double>, longitude: ClosedRange<Double>) {
        let latitudeDelta = radiusMeters / 111_000.0
        let longitudeDelta = radiusMeters / (111_000.0 * cos(latitude * .pi / 180))
        
        return (
            (latitude - latitudeDelta)...(latitude + latitudeDelta),
            (longitude - longitudeDelta)...(longitude + longitudeDelta)
        )
    }
    
    static func finalSelectionScore(
        selectionScore: Int,
        distance: Double,
        radiusMeters: Double
    ) -> Int {
        let clampedDistance = min(max(distance, 0), radiusMeters)
        let distanceBonus = Int(((radiusMeters - clampedDistance) / radiusMeters * 10.0).rounded())
        
        return selectionScore + distanceBonus
    }
    
    static func distance(
        fromLatitude: Double,
        fromLongitude: Double,
        to facility: Facility
    ) -> Double {
        guard let latitude = facility.latitude,
              let longitude = facility.longitude else {
            return Double.greatestFiniteMagnitude
        }
        
        let earthRadius = 6_371_000.0
        let startLatitude = fromLatitude * .pi / 180
        let endLatitude = latitude * .pi / 180
        let latitudeDelta = (latitude - fromLatitude) * .pi / 180
        let longitudeDelta = (longitude - fromLongitude) * .pi / 180
        let a = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

// 기존 RecommendSportsUseCase
extension FetchHomeRecommendationsUseCase {
    private let repository: SportRecommendationRuleRepositoryProtocol
    private let calendar: Calendar
    
    init(
        repository: SportRecommendationRuleRepositoryProtocol,
        calendar: Calendar = .current
    ) {
        self.repository = repository
        self.calendar = calendar
    }
    
    func execute(profile: UserProfile) -> Single<[RecommendedSport]> {
        executePersonalizedScores(profile: profile)
            .map(Self.visibleRecommendations)
    }
    
    func executePersonalizedScores(profile: UserProfile) -> Single<[RecommendedSport]> {
        repository.fetchActiveRules()
            .map { [calendar] rules in
                Self.scoredSports(
                    profile: profile,
                    rules: rules,
                    calendar: calendar,
                    includesPersonalization: true
                )
            }
    }
    
    func executeCategory(profile: UserProfile) -> Single<[RecommendedSport]> {
        repository.fetchActiveRules()
            .map { [calendar] rules in
                Self.scoredSports(
                    profile: profile,
                    rules: rules,
                    calendar: calendar,
                    includesPersonalization: false
                )
            }
    }
}

private extension RecommendSportsUseCase {
    static let primaryThreshold = 70
    static let fallbackThreshold = 60
    static let minimumRecommendationCount = 3
    static let maximumVisibleRecommendationCount = 8
    static let preferredCategoryBonus = 5
    
    static func scoredSports(
        profile: UserProfile,
        rules: [SportRecommendationRule],
        calendar: Calendar,
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
                        calendar: calendar,
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
        calendar: Calendar,
        includesPersonalization: Bool
    ) -> Int {
        let ageScore = rule.ageWeights[ageGroup(for: profile.birthDate, calendar: calendar)] ?? 0
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

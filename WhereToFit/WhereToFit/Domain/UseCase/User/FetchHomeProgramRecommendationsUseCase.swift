//
//  FetchHomeProgramRecommendationsUseCase.swift
//  WhereToFit
//
//  Created by 변예린 on 6/21/26.
//

import Foundation
import RxSwift

final class FetchHomeProgramRecommendationsUseCase {
    private struct LocationContext {
        let address: String
        let latitude: Double
        let longitude: Double
    }
    
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
    
    func execute(profile: UserProfile?, location: UserLocation?) -> Single<[HomeRecommendedProgram]> {
        let context = Self.locationContext(from: location)
        
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

private extension FetchHomeProgramRecommendationsUseCase {
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
    
    private static func locationContext(from location: UserLocation?) -> LocationContext {
        LocationContext(
            address: location?.address ?? defaultLocationAddress,
            latitude: location?.latitude ?? defaultLocationLatitude,
            longitude: location?.longitude ?? defaultLocationLongitude
        )
    }
    
    private func fetchCandidates(context: LocationContext, radiusMeters: Double) -> Single<CandidateResult> {
        fetchNearbyFacilities(context: context, radiusMeters: radiusMeters)
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
                                context: context
                            ),
                            radiusMeters: radiusMeters
                        )
                    }
            }
    }
    
    private func fetchNearbyFacilities(context: LocationContext, radiusMeters: Double) -> Single<[Facility]> {
        let bounds = Self.coordinateBounds(
            latitude: context.latitude,
            longitude: context.longitude,
            radiusMeters: radiusMeters
        )
        
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
        context: LocationContext
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
        categorySports: [RecommendedSports],
        personalizedSports: [RecommendedSports],
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

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

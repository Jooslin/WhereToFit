//
//  FavoriteDetailResolver.swift
//  WhereToFit
//
//  Created by 김주희 on 6/21/26.
//

import Foundation
import RxSwift

struct FavoriteDetailResolveInput {
    let targetType: FavoriteTargetType
    let targetID: String
    let name: String
    let facilityLabelText: String?
    let time: String
    let distance: String
    let price: String
    let reservationMethodText: String?
    let imageURLString: String?
    let sportsCategoryRawValue: String?
}

struct FavoriteDetailTarget {
    let facility: FitnessFacility
    let relatedPrograms: [FitnessFacility]
}

final class FavoriteDetailResolver {
    private let sportsRepository: SportsRepositoryProtocol
    private let favoriteRepository: FavoriteRepositoryProtocol
    private let pageSize = 1_000

    init(
        sportsRepository: SportsRepositoryProtocol = SportsRepository(),
        favoriteRepository: FavoriteRepositoryProtocol
    ) {
        self.sportsRepository = sportsRepository
        self.favoriteRepository = favoriteRepository
    }

    func resolve(input: FavoriteDetailResolveInput) -> Single<FavoriteDetailTarget> {
        resolveTarget(input: input)
            .flatMap { [favoriteRepository] target in
                favoriteRepository.fetchFavorites()
                    .map { favorites in
                        Self.applyingFavoriteKeys(
                            Set(favorites.map(FavoriteTargetKey.init)),
                            to: target
                        )
                    }
                    .catch { _ in .just(target) }
            }
    }
}

private extension FavoriteDetailResolver {
    enum ResolverError: Error {
        case facilityNotFound
    }

    func resolveTarget(input: FavoriteDetailResolveInput) -> Single<FavoriteDetailTarget> {
        switch input.targetType {
        case .facility:
            return resolveFacility(input: input)

        case .program:
            return resolveProgram(input: input)
        }
    }

    func resolveFacility(input: FavoriteDetailResolveInput) -> Single<FavoriteDetailTarget> {
        fetchFacility(sourceFacilityID: input.targetID)
            .flatMap { [self] facility in
                fetchPrograms(sourceFacilityID: input.targetID, sourceFacility: facility)
                    .map { programs in
                        FavoriteDetailTarget(
                            facility: facility,
                            relatedPrograms: programs
                        )
                    }
                    .catch { _ in
                        .just(
                            FavoriteDetailTarget(
                                facility: facility,
                                relatedPrograms: []
                            )
                        )
                    }
            }
            .catch { _ in
                .just(
                    FavoriteDetailTarget(
                        facility: Self.makeFallbackFacility(for: input),
                        relatedPrograms: []
                    )
                )
            }
    }

    func resolveProgram(input: FavoriteDetailResolveInput) -> Single<FavoriteDetailTarget> {
        guard let sourceFacilityID = Self.sourceFacilityID(fromProgramTargetID: input.targetID) else {
            return .just(
                FavoriteDetailTarget(
                    facility: Self.makeFallbackFacility(for: input),
                    relatedPrograms: []
                )
            )
        }

        return fetchFacility(sourceFacilityID: sourceFacilityID)
            .flatMap { [self] sourceFacility in
                fetchPrograms(sourceFacilityID: sourceFacilityID, sourceFacility: sourceFacility)
                    .map { programs in
                        let selectedProgram = programs.first {
                            FavoriteTargetKey(targetType: .program, facility: $0).targetID == input.targetID
                        } ?? Self.makeFallbackFacility(for: input, sourceFacility: sourceFacility)

                        return FavoriteDetailTarget(
                            facility: selectedProgram,
                            relatedPrograms: programs
                        )
                    }
                    .catch { _ in
                        .just(
                            FavoriteDetailTarget(
                                facility: Self.makeFallbackFacility(for: input, sourceFacility: sourceFacility),
                                relatedPrograms: []
                            )
                        )
                    }
            }
            .catch { _ in
                .just(
                    FavoriteDetailTarget(
                        facility: Self.makeFallbackFacility(for: input),
                        relatedPrograms: []
                    )
                )
            }
    }

    func fetchFacility(sourceFacilityID: String) -> Single<FitnessFacility> {
        sportsRepository.fetchFacilities(
            facilityIDs: [sourceFacilityID],
            limit: 1,
            offset: 0,
            order: .ascending
        )
        .map { page in
            guard let matchedFacility = page.items.first(where: { $0.id == sourceFacilityID }),
                  let facility = SportsFacilityRepository.makeFitnessFacility(from: matchedFacility) else {
                throw ResolverError.facilityNotFound
            }

            return facility
        }
    }

    func fetchPrograms(
        sourceFacilityID: String,
        sourceFacility: FitnessFacility
    ) -> Single<[FitnessFacility]> {
        fetchProgramPages(
            sourceFacilityID: sourceFacilityID,
            offset: 0,
            accumulated: []
        )
        .map { programs in
            programs.compactMap { program in
                guard program.publicFacilityID == sourceFacilityID else { return nil }
                return SportsFacilityRepository.makeFitnessFacility(
                    from: program,
                    facility: sourceFacility
                )
            }
        }
    }

    func fetchProgramPages(
        sourceFacilityID: String,
        offset: Int,
        accumulated: [Program]
    ) -> Single<[Program]> {
        sportsRepository.fetchPrograms(
            facilityIDs: [sourceFacilityID],
            limit: pageSize,
            offset: offset,
            order: .ascending
        )
        .flatMap { [self] page -> Single<[Program]> in
            let programs = accumulated + page.items
            guard let nextOffset = page.nextOffset else {
                return .just(programs)
            }

            return fetchProgramPages(
                sourceFacilityID: sourceFacilityID,
                offset: nextOffset,
                accumulated: programs
            )
        }
    }
}

private extension FavoriteDetailResolver {
    static func applyingFavoriteKeys(
        _ favoriteKeys: Set<FavoriteTargetKey>,
        to target: FavoriteDetailTarget
    ) -> FavoriteDetailTarget {
        var facility = target.facility
        facility.isFavorite = favoriteKeys.contains(FavoriteTargetKey(facility: facility))

        let relatedPrograms = target.relatedPrograms.map { program in
            var favoriteProgram = program
            favoriteProgram.isFavorite = favoriteKeys.contains(
                FavoriteTargetKey(targetType: .program, facility: program)
            )
            return favoriteProgram
        }

        return FavoriteDetailTarget(
            facility: facility,
            relatedPrograms: relatedPrograms
        )
    }

    static func makeFallbackFacility(
        for input: FavoriteDetailResolveInput,
        sourceFacility: FitnessFacility? = nil
    ) -> FitnessFacility {
        let category = category(from: input)
        let timeRange = timeRange(from: input.time) ?? sourceFacility?.availableTimeRange ?? TimeRange(startHour: 0, endHour: 24)
        let targetURL = sourceFacility?.reservationURL ?? URL(string: "https://www.seoul.go.kr")!

        return FitnessFacility(
            id: input.targetID,
            name: input.name,
            address: sourceFacility?.address ?? "주소 정보 없음",
            phoneNumber: sourceFacility?.phoneNumber ?? "전화번호 정보 없음",
            category: category,
            coordinate: sourceFacility?.coordinate ?? GeoCoordinate(latitude: 37.576022, longitude: 126.976900),
            distanceInMeters: distanceInMeters(from: input.distance),
            price: price(from: input.price),
            priceDisplayText: input.price,
            rawPriceText: input.price,
            availableDays: sourceFacility?.availableDays ?? Weekday.allCases,
            availableTimeRange: timeRange,
            imageURL: imageURL(from: input.imageURLString) ?? sourceFacility?.imageURL,
            isFavorite: true,
            requiresReservation: input.reservationMethodText != nil,
            matchingRate: sourceFacility?.matchingRate,
            reservationURL: targetURL,
            homepageURL: sourceFacility?.homepageURL,
            description: sourceFacility?.description ?? "상세 정보가 준비 중입니다.",
            locationName: input.facilityLabelText?
                .replacingOccurrences(of: "|", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? sourceFacility?.locationName,
            facilityType: input.sportsCategoryRawValue ?? sourceFacility?.facilityType,
            operatingHoursText: sourceFacility?.operatingHoursText ?? input.time,
            applicationMethodText: input.reservationMethodText ?? sourceFacility?.applicationMethodText ?? "신청 방법 정보 없음",
            introduction: sourceFacility?.introduction ?? "시설 소개 정보 없음",
            amenities: sourceFacility?.amenities ?? [],
            parkingInfo: sourceFacility?.parkingInfo ?? "주차 정보 없음",
            sourceKind: input.targetType == .facility ? .facility : .program,
            sourceFacilityID: input.targetType == .facility
                ? input.targetID
                : sourceFacility?.sourceFacilityID ?? sourceFacilityID(fromProgramTargetID: input.targetID),
            sourceProgramID: nil
        )
    }

    static func sourceFacilityID(fromProgramTargetID targetID: String) -> String? {
        guard let range = targetID.range(of: "-facility-", options: .backwards) else {
            return nil
        }

        let sourceFacilityID = String(targetID[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return sourceFacilityID.isEmpty ? nil : sourceFacilityID
    }

    static func category(from input: FavoriteDetailResolveInput) -> FacilityCategory {
        let categoryText = input.sportsCategoryRawValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let categoryText,
           let category = FacilityCategory.allCases.first(where: {
               $0.rawValue == categoryText || $0.title == categoryText
           }) {
            return category
        }

        return .multipurpose
    }

    static func timeRange(from text: String) -> TimeRange? {
        let numbers = text
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        guard let startHour = numbers.first else { return nil }
        let endHour = numbers.dropFirst(2).first ?? numbers.dropFirst().first ?? startHour + 1
        return TimeRange(startHour: startHour, endHour: min(max(endHour, startHour + 1), 24))
    }

    static func price(from text: String) -> Int {
        Int(text.filter(\.isNumber)) ?? 0
    }

    static func distanceInMeters(from text: String) -> Int {
        let numberText = text.filter { $0.isNumber || $0 == "." }
        let number = Double(numberText) ?? 0
        return text.lowercased().contains("km") ? Int(number * 1_000) : Int(number)
    }

    static func imageURL(from imageURLString: String?) -> URL? {
        guard let imageURLString,
              imageURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return nil
        }

        let trimmedURLString = imageURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmedURLString) {
            return url
        }

        guard let encodedURLString = trimmedURLString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else {
            return nil
        }

        return URL(string: encodedURLString)
    }
}

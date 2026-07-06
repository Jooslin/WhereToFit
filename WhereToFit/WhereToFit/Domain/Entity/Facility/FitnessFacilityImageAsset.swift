//
//  FitnessFacilityImageAsset.swift
//  WhereToFit
//
//  Created by 김주희 on 6/10/26.
//

import Foundation

nonisolated enum FacilityImageContext {
    case facility
    case program
}

nonisolated extension FitnessFacility {
    var facilityPlaceholderImageName: String {
        placeholderImageName(for: .facility)
    }

    var programPlaceholderImageName: String {
        placeholderImageName(for: .program)
    }

    func placeholderImageName(for context: FacilityImageContext) -> String {
        guard category == .multipurpose else {
            return category.placeholderImageName(for: context)
        }

        let searchText = [
            name,
            locationName,
            facilityType,
            description,
            introduction,
            category.title
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        if let imageName = Self.keywordImageName(for: searchText) {
            return Self.contextualImageName(imageName, for: context)
        }

        return category.placeholderImageName(for: context)
    }

    nonisolated private static func contextualImageName(
        _ imageName: String,
        for context: FacilityImageContext
    ) -> String {
        guard context == .facility else {
            return imageName
        }

        switch imageName {
        case "sportsAqua":
            return "centerImageSwimming"
        case "sportsTennis":
            return "centerImageTennis"
        default:
            return imageName
        }
    }

    nonisolated private static func keywordImageName(for text: String) -> String? {
        let normalizedText = text.normalizedFacilityImageSearchText
        let candidates: [(keywords: [String], imageName: String)] = [
            (["수영", "수중", "아쿠아"], "sportsAqua"),
            (["테니스", "정구", "배드민턴", "탁구"], "sportsTennis"),
            (["축구", "풋살"], "sportsSoccer"),
            (["농구", "배구"], "sportsBall"),
            (["클라이밍", "암벽"], "sportsOthers"),
            (["사이클", "자전거", "스피닝"], "sportsCycle"),
            (["러닝", "달리기", "마라톤"], "sportsRunning"),
            (["등산", "트레킹", "하이킹"], "sportsHiking"),
            (["스케이트", "빙상"], "sportsIce"),
            (["필라테스", "리포머"], "sportsPilates"),
            (["요가"], "sportsYoga"),
            (["태권도", "무술", "무도", "격투", "검도", "유도"], "sportsMartial"),
            (["에어로빅", "댄스", "무용", "발레"], "sportsDance"),
            (["스트레칭", "체조"], "sportsGymnastic"),
            (["헬스", "피트니스", "체력단련", "웨이트", "근력"], "sportsHealth")
        ]

        return candidates.first { candidate in
            candidate.keywords.contains { normalizedText.contains($0.normalizedFacilityImageSearchText) }
        }?.imageName
    }
}

private extension FacilityCategory {
    nonisolated func placeholderImageName(for context: FacilityImageContext) -> String {
        switch self {
        case .swimming, .survivalSwimming, .aquaticHealthGymnastics, .aquaRobics, .aquaWalking, .aquathlon, .artisticSwimming, .scubaDiving:
            return context == .facility ? "centerImageSwimming" : "sportsAqua"
        case .basketball, .volleyball, .bowling, .billiards, .gateball, .floorball:
            return "sportsBall"
        case .badminton, .tableTennis, .tennis, .squash, .racquetball, .pickleball, .golf, .parkGolf:
            return context == .facility ? "centerImageTennis" : "sportsTennis"
        case .soccer, .futsal, .baseball:
            return "sportsSoccer"
        case .cycling, .runBike, .triathlon, .spinningBike:
            return "sportsCycle"
        case .dance, .lineDance, .broadcastDance, .bellyDance, .sportsDance, .zumbaDance, .dietDance, .ballet, .traditionalDance, .koreanDance, .aerobics, .dietRobics, .seniorRobics, .taebo, .jumpingDiet, .jumpingTrampoline:
            return "sportsDance"
        case .gym, .healthPT, .bodybuilding:
            return "sportsHealth"
        case .gx, .trx, .circuitTraining, .fitBalance, .womensCircuitExercise:
            return "sportsFitness"
        case .gymnastics, .kuksundo, .koreanQigong, .taiChi, .lifeGymnastics, .stretching:
            return "sportsGymnastic"
        case .hiking:
            return "sportsHiking"
        case .skating, .speedSkating, .figureSkating, .skiing, .rollerSkating:
            return "sportsIce"
        case .kendo, .boxing, .judo, .taekwondo, .taekkyeon, .fencing, .traditionalArchery:
            return "sportsMartial"
        case .climbing, .sBoard:
            return "sportsOthers"
        case .yoga, .powerYoga:
            return "sportsYoga"
        case .pilates, .snpe:
            return "sportsPilates"
        case .lifeSports, .childSports, .infantSports, .jumpRope, .womensHealthClass, .bodySkillRelease:
            return "sportsRecreational"
        case .running, .jogging, .athletics:
            return "sportsRunning"
        case .boccia:
            return "sportsAdaptive"
        case .multipurpose:
            return "sportsHealth"
        }
    }
}

private extension String {
    nonisolated var normalizedFacilityImageSearchText: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

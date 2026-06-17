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
            return context == .facility ? facilityImageName(for: imageName) : imageName
        }

        return category.placeholderImageName(for: context)
    }

    private func facilityImageName(for programImageName: String) -> String {
        switch programImageName {
        case "Soccer":
            return "CenterImageSoccer"
        case "Swimming":
            return "CenterImageSwimming"
        case "Tennis":
            return "CenterImageTennis"
        default:
            return programImageName
        }
    }

    private static func keywordImageName(for text: String) -> String? {
        let normalizedText = text.normalizedFacilityImageSearchText
        let candidates: [(keywords: [String], imageName: String)] = [
            (["수영", "수중", "아쿠아"], "Swimming"),
            (["테니스", "정구", "배드민턴", "탁구"], "Tennis"),
            (["축구", "풋살"], "Soccer"),
            (["농구", "배구"], "Basketball"),
            (["클라이밍", "암벽"], "Climbing"),
            (["사이클", "자전거", "스피닝"], "Cycle"),
            (["러닝", "달리기", "마라톤"], "Running"),
            (["등산", "트레킹", "하이킹"], "Hiking"),
            (["스케이트", "빙상"], "Skating"),
            (["필라테스", "리포머"], "Pilates"),
            (["요가"], "Yoga"),
            (["태권도", "무술", "무도", "격투", "검도", "유도"], "TKD"),
            (["에어로빅", "댄스", "무용", "발레"], "Airobic"),
            (["스트레칭", "체조"], "Stretching"),
            (["헬스", "피트니스", "체력단련", "웨이트", "근력"], "Gym")
        ]

        return candidates.first { candidate in
            candidate.keywords.contains { normalizedText.contains($0.normalizedFacilityImageSearchText) }
        }?.imageName
    }
}

private extension FacilityCategory {
    func placeholderImageName(for context: FacilityImageContext) -> String {
        let programImageName: String

        switch self {
        case .soccer, .futsal, .baseball, .floorball:
            programImageName = "Soccer"
        case .basketball, .volleyball, .bowling, .billiards, .gateball:
            programImageName = "Basketball"
        case .badminton, .tableTennis, .tennis, .squash, .racquetball, .pickleball, .golf, .parkGolf:
            programImageName = "Tennis"
        case .gym, .healthPT, .bodybuilding, .gx, .trx, .circuitTraining, .spinningBike, .fitBalance, .womensCircuitExercise, .running, .jogging, .athletics, .cycling, .runBike, .triathlon, .lifeSports, .childSports, .infantSports, .jumpRope, .womensHealthClass, .bodySkillRelease, .boccia:
            programImageName = "Gym"
        case .yoga, .powerYoga:
            programImageName = "Yoga"
        case .pilates, .snpe:
            programImageName = "Pilates"
        case .swimming, .survivalSwimming, .aquaticHealthGymnastics, .aquaRobics, .aquaWalking, .aquathlon, .artisticSwimming, .scubaDiving:
            programImageName = "Swimming"
        case .climbing, .sBoard, .hiking:
            programImageName = "Climbing"
        case .skating, .speedSkating, .figureSkating, .skiing, .rollerSkating:
            programImageName = "Skating"
        case .dance, .lineDance, .broadcastDance, .bellyDance, .sportsDance, .zumbaDance, .dietDance, .ballet, .traditionalDance, .koreanDance, .gymnastics, .kuksundo, .koreanQigong, .taiChi, .lifeGymnastics, .stretching, .aerobics, .dietRobics, .seniorRobics, .taebo, .jumpingDiet, .jumpingTrampoline:
            programImageName = "Airobic"
        case .kendo, .boxing, .judo, .taekwondo, .taekkyeon, .fencing, .traditionalArchery:
            programImageName = "TKD"
        case .multipurpose:
            programImageName = "Gym"
        }

        if context == .program {
            return programImageName
        }

        switch programImageName {
        case "Soccer":
            return "CenterImageSoccer"
        case "Swimming":
            return "CenterImageSwimming"
        case "Tennis":
            return "CenterImageTennis"
        default:
            return programImageName
        }
    }
}

private extension String {
    var normalizedFacilityImageSearchText: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

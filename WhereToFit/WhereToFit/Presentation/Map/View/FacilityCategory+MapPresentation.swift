//
//  FacilityCategory+MapPresentation.swift
//  WhereToFit
//
//  Created by 김주희 on 6/16/26.
//

import UIKit

extension FacilityCategory {
    /// 지도/리스트에서 카테고리를 시각적으로 구분하기 위한 Presentation 전용 색상입니다.
    /// Domain enum 자체에 UIKit 의존성을 넣지 않기 위해 별도 extension으로 분리했습니다.
    var mapTintColor: UIColor {
        switch self {
        case .soccer, .futsal, .baseball, .floorball:
            return .systemGreen
        case .basketball, .volleyball, .badminton, .tableTennis, .squash, .racquetball, .pickleball, .gateball, .billiards, .bowling:
            return .systemRed
        case .gym, .healthPT, .bodybuilding, .gx, .trx, .circuitTraining, .spinningBike, .fitBalance, .womensCircuitExercise, .running, .jogging, .athletics, .cycling, .runBike, .triathlon, .lifeSports, .childSports, .infantSports, .jumpRope, .womensHealthClass, .bodySkillRelease, .boccia:
            return .systemOrange
        case .yoga, .powerYoga, .pilates, .snpe, .dance, .lineDance, .broadcastDance, .bellyDance, .sportsDance, .zumbaDance, .dietDance, .ballet, .traditionalDance, .koreanDance, .gymnastics, .kuksundo, .koreanQigong, .taiChi, .lifeGymnastics, .stretching, .aerobics, .dietRobics, .seniorRobics, .taebo, .jumpingDiet, .jumpingTrampoline:
            return .systemPink
        case .swimming, .survivalSwimming, .aquaticHealthGymnastics, .aquaRobics, .aquaWalking, .aquathlon, .artisticSwimming, .scubaDiving:
            return .systemTeal
        case .tennis, .golf, .parkGolf:
            return .systemYellow
        case .climbing, .sBoard, .hiking:
            return .systemIndigo
        case .skating, .speedSkating, .figureSkating, .skiing, .rollerSkating:
            return .systemCyan
        case .kendo, .boxing, .judo, .taekwondo, .taekkyeon, .fencing, .traditionalArchery:
            return .systemPurple
        case .multipurpose:
            return .systemGray4
        }
    }

    /// 지도 마커에 표시할 asset 이름입니다.
    /// 여러 세부 종목이 같은 아이콘을 공유하므로, 카운트 마커에서도 이 값을 기준으로 개수를 합산합니다.
    var markerIconName: String {
        switch self {
        case .soccer, .futsal, .baseball, .basketball, .volleyball, .badminton, .tableTennis, .tennis, .squash, .racquetball, .pickleball, .golf, .parkGolf, .gateball, .billiards, .bowling, .floorball:
            return "ballSports"
        case .gym, .healthPT, .bodybuilding:
            return "weightTraining"
        case .gx, .trx, .circuitTraining, .spinningBike, .fitBalance, .womensCircuitExercise, .aerobics, .dietRobics, .seniorRobics, .taebo, .jumpingDiet, .jumpingTrampoline:
            return "fitness"
        case .yoga, .powerYoga, .pilates, .snpe:
            return "yogaPilates"
        case .swimming, .survivalSwimming, .aquaticHealthGymnastics, .aquaRobics, .aquaWalking, .aquathlon, .artisticSwimming, .scubaDiving:
            return "aquaticSports"
        case .running, .jogging, .athletics, .cycling, .runBike, .triathlon:
            return "runningCycle"
        case .lifeSports, .childSports, .infantSports, .jumpRope, .womensHealthClass, .bodySkillRelease:
            return "recreationalSports"
        case .boccia:
            return "adaptivePhysicalEducation"
        case .climbing, .sBoard, .hiking, .rollerSkating:
            return "other"
        case .skating, .speedSkating, .figureSkating, .skiing:
            return "iceSports"
        case .dance, .lineDance, .broadcastDance, .bellyDance, .sportsDance, .zumbaDance, .dietDance, .ballet, .traditionalDance, .koreanDance:
            return "dance"
        case .gymnastics, .kuksundo, .koreanQigong, .taiChi, .lifeGymnastics, .stretching:
            return "gymnastics"
        case .kendo, .boxing, .judo, .taekwondo, .taekkyeon, .fencing, .traditionalArchery:
            return "martialArts"
        case .multipurpose:
            return "recreationalSports"
        }
    }
}

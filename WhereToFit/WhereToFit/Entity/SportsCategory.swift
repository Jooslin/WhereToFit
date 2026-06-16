//
//  SportsCategory.swift
//  WhereToFit
//
//  Created by 변예린 on 6/11/26.
//
import Foundation
import UIKit

enum SportsCategory: String, Hashable {
    case health = "헬스"
    case fitness = "피트니스"
    case yogaPilates = "요가/필라"
    case gymnastics = "체조"
    case dance = "댄스/무용"
    case aquaticSports = "수중"
    case ballSports = "구기"
    case iceSports = "빙상"
    case martialArts = "무도/격투"
    case runningCycle = "러닝/사이클"
    case recreationalSports = "생활체육"
    case adaptivePhysicalEducation = "특수체육"
    case other = "기타"
    
    static let sportsByCategory: [SportsCategory: [String]] = [
        .health: ["헬스", "헬스PT", "보디빌딩"],
        .fitness: ["GX", "TRX", "서킷트레이닝", "스피닝바이크", "에어로빅", "다이어트로빅", "시니어로빅", "태보", "점핑다이어트", "점핑트램폴린", "핏밸런스", "여성순환운동"],
        .yogaPilates: ["요가", "파워요가", "필라테스", "SNPE"],
        .gymnastics: ["국선도", "국학기공", "태극권", "생활체조", "체조", "스트레칭"],
        .dance: ["댄스", "라인댄스", "방송댄스", "벨리댄스", "스포츠댄스", "줌바댄스", "다이어트댄스", "발레", "전통무용", "한국무용"],
        .aquaticSports: ["수영", "생존수영", "수중보건체조", "아쿠아로빅", "아쿠아워킹", "아쿠아슬론", "아티스틱 스위밍", "스킨스쿠버"],
        .ballSports: ["농구", "축구", "풋살", "야구", "배드민턴", "탁구", "테니스", "스쿼시", "라켓볼", "피클볼", "골프", "파크골프", "게이트볼", "당구", "볼링", "플로어볼"],
        .iceSports: ["스케이트", "스피드 스케이팅", "피겨", "스키"],
        .martialArts: ["검도", "복싱", "유도", "태권도", "택견", "펜싱", "국궁"],
        .runningCycle: ["러닝", "달리기", "육상", "자전거", "런바이크", "철인 3종"],
        .recreationalSports: ["생활체육", "아동체육", "유아체육", "줄넘기", "여성건강교실", "바디스킬릴리즈"],
        .adaptivePhysicalEducation: ["보치아"],
        .other: ["기타"]
    ]
    
    var sports: [String] {
        Self.sportsByCategory[self] ?? []
    }

    var icon: UIImage {
        switch self { 
        case .health: .weightTraining
        case .fitness: .fitness
        case .yogaPilates: .yogaPilates
        case .gymnastics: .gymnastics
        case .dance: .dance
        case .aquaticSports: .aquaticSports
        case .ballSports: .ballSports
        case .iceSports: .iceSports
        case .martialArts: .martialArts
        case .runningCycle: .runningCycle
        case .recreationalSports: .recreationalSports
        case .adaptivePhysicalEducation: .adaptivePhysicalEducation
        case .other: .other
        }
    }
    
    var image: UIImage {
        switch self {
        case .health: .sportsHealth
        case .fitness: .sportsFitness
        case .yogaPilates: .sportsYoga
        case .gymnastics: .sportsGymnastic
        case .dance: .sportsDance
        case .aquaticSports: .sportsAqua
        case .ballSports: .sportsBall
        case .iceSports: .sportsIce
        case .martialArts: .sportsMartial
        case .runningCycle: .sportsRunning
        case .recreationalSports: .sportsRecreational
        case .adaptivePhysicalEducation: .sportsAdaptive
        case .other: .sportsOthers
        }
    }
    
    init(sport: String?) {
        let value = sport?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        self = Self.sportsByCategory.first { element in
            element.value.contains(value)
        }?.key ?? .other
    }
}

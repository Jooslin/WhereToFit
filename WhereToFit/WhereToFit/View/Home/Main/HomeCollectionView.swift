//
//  HomeCollectionView.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import UIKit

final class HomeCollectionView: UICollectionView {
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
        contentInset = .init(top: 0, left: 0, bottom: 50, right: 0)
        showsVerticalScrollIndicator = false
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HomeCollectionView {
    nonisolated
    enum Section: Int {
        case weather = 0
        case recommend
        case recommendReason
        case onboarding
        case program
//        case notice
    }
    
    nonisolated
    enum Item: Hashable {
        case weather(WeatherSectionItem)
        case recommend(RecommendedSport)
        case recommendReason(String)
        case onboarding
        case program(ProgramSectionItem)
//        case notice
    }
}

extension HomeCollectionView {
    //TODO: schedule
    struct WeatherSectionItem: Hashable {
        let weeklyDate: [WeeklyDate] // 주간 요일, day
//        let schedule: [] - 운동 종류 모델 사용
        let weather: Weather
        let isNight: Bool
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(weeklyDate)
            hasher.combine(weather)
            hasher.combine(isNight)
        }
    }
    
    struct ProgramSectionItem: Hashable {
        let id: Int
        let imageName: String
        let matchRate: Double?
        let place: String
        let name: String
        let facility: Facility
        
        static func == (lhs: ProgramSectionItem, rhs: ProgramSectionItem) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

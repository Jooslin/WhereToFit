//
//  OnboardViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import Then
import RxSwift
import ReactorKit

final class OnboardingViewController: BaseViewController<OnboardingReactor> {
    let onboardingView = OnboardingFacilityView()
    override func loadView() {
        view = onboardingView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let program = Program(
            id: 1,
            facilityName: "구미시민운동장",
            facilityLocation: "경상북도 구미시 박정희로 375",

            className: "성인 초급 배드민턴 교실",
            sport: "배드민턴",
            classDescription: "배드민턴의 기본 자세와 규칙을 배우는 입문 과정입니다.",

            targetAges: [.adult],
            levels: [.beginner],
            isDisabledAccessible: true,

            priceAmount: 50000,
            priceUnit: .month,
            priceNote: "라켓 대여 가능",

            days: ["월", "수", "금"],
            startTime: "19:00",
            endTime: "20:30",

            phoneNumber: "054-480-1234",
            reservationMethods: [.online, .phone],
            homepageURL: "https://www.gumi.go.kr"
        )
        
        onboardingView.setSnapshot(with: [
            .list: [OnboardingFacilityView.Item.list(program)],
                .button: [OnboardingFacilityView.Item.button]
        ])
    }
    
    override func bind(reactor: OnboardingReactor) {
    }
    
}


#Preview {
    OnboardingViewController(reactor: OnboardingReactor())
}

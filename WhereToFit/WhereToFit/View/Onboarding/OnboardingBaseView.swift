//
//  OnboardingBaseView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/4/26.
//

import UIKit
import SnapKit
import Then

class OnboardingBaseView: UIView {
    let titleView = TitleView(leftButtonImage: .arrowLeft)
    let progressBar = RoundedProgressView(progressViewStyle: .bar).then {
        $0.progressTintColor = .primary400
        $0.trackTintColor = .gray100
    }
    let nextButton = DesignButton(config: .largeFilledBlue).then {
        $0.title = "다음"
    }
    
    let titleLabel = UILabel(config: .title20Semibold)
    let subTitleLabel = UILabel(config: .body14Regular)
    
    let step: OnboardingStep?
    
    init(frame: CGRect, step: OnboardingStep) {
        self.step = step
        super.init(frame: frame)
        
        backgroundColor = .white
        
        titleLabel.text = step.title
        subTitleLabel.text = step.subTitle
        progressBar.setProgress(step.progress, animated: false)
        
        let labelStackView = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel]).then {
            $0.axis = .vertical
            $0.alignment = .leading
            $0.spacing = 8
        }
        
        addSubview(titleView)
        addSubview(labelStackView)
        addSubview(nextButton)
        
        titleView.addSubview(progressBar)
        
        titleView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview()
        }
        
        progressBar.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(20)
            $0.horizontalEdges.equalToSuperview().inset(48)
        }
        
        labelStackView.snp.makeConstraints {
            $0.top.equalTo(titleView.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        nextButton.snp.makeConstraints {
            $0.bottom.equalTo(safeAreaLayoutGuide).inset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum OnboardingStep: Int, CaseIterable {
    case start
    case personalInfo
    case experience
    case goal
    case preference
    case disabled
    case facility
    case end
    
    var previous: OnboardingStep? {
        guard let index = Self.allCases.firstIndex(of: self),
              index > Self.allCases.startIndex else {
            return nil
        }
        
        return Self.allCases[Self.allCases.index(before: index)]
    }
    
    var next: OnboardingStep? {
        guard let index = Self.allCases.firstIndex(of: self) else {
            return nil
        }
        
        let nextIndex = Self.allCases.index(after: index)
        guard nextIndex < Self.allCases.endIndex else {
            return nil
        }
        
        return Self.allCases[nextIndex]
    }
    
    var title: String {
        switch self {
        case .start, .end: ""
        case .personalInfo: "안녕하세요!"
        case .experience: "운동 경험을 알려주세요!"
        case .goal: "운동 목표는 무엇인가요?"
        case .preference: "어떤 운동을 좋아하세요?"
        case .disabled: "불편한 신체부위가 있나요?"
        case .facility: "공공체육시설을 이용중이신가요?"
        }
    }
    
    var subTitle: String {
        switch self {
        case .start, .end: ""
        case .personalInfo: "운동 추천을 위해 몇 가지 정보를 알려주세요."
        case .experience: "스스로 생각하는 정도를 선택해주세요."
        case .goal: "달성하고 싶은 목표를 선택해주세요."
        case .preference: "관심있는 운동을 모두 선택해주세요."
        case .disabled: "운동을 하면 무리가 가는 부위를 알려주세요."
        case .facility: "이용중인 프로그램이 있다면 등록해주세요."
        }
    }
    
    var progress: Float {
        guard self != .start, self != .end else {
            return 0
        }
        
        return Float(rawValue) / Float(Self.allCases.count - 2)
    }
    
    //TODO: 데이터 모델 반영하기
    var categories: [String] {
        switch self {
        case .goal:
            return ["근력 향상", "다이어트", "체력 향상", "자세 교정", "건강 관리", "스트레스 해소"]
        case .preference:
            return ["헬스", "피트니스", "요가/필라", "체조", "댄스/무용", "수중", "구기", "빙상", "무도/격투", "러닝/사이클", "생활체육", "특수체육"]
        case .disabled:
            return ["어지럼증", "목", "어깨", "팔꿈치", "손목", "허리", "무릎", "발목"]
        default:
            return []
        }
    }
}


//MARK: Component
final class RoundedProgressView: UIProgressView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let radius = bounds.height / 2
        layer.cornerRadius = radius
    }
}

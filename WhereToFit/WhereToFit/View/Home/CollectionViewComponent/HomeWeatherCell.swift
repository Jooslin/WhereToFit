//
//  HomeWeatherCell.swift
//  WhereToFit
//
//  Created by 변예린 on 5/30/26.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class HomeWeatherCell: UICollectionViewCell {
    private(set) var disposeBag = DisposeBag()
    
    private lazy var weeklyDateView = generateWeeklyDateView()
    private let weatherImageView = UIImageView()
    private let weatherLabel = UILabel(config: .body14Medium)
    private let weatherDescriptionLabel = UILabel(config: .title24)
    private let reservationLabel = UILabel(config: .body16Medium)
    
    fileprivate let registrationButton = DesignButton(config: .smallBorderBlue).then {
        $0.title = "프로그램 등록"
    }
    fileprivate let recordButton = DesignButton(config: .smallFilledBlue).then {
        $0.title = "운동 기록"
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        
        // 이미지 초기화
        weeklyDateView.arrangedSubviews.forEach {
            if let dayView = $0 as? OneDayView {
                dayView.dateImageView.image = nil
            }
        }
    }
}

//MARK: Configure
extension HomeWeatherCell {
    func configure() {
        
    }
}

//MARK: Layout
extension HomeWeatherCell {
    private func setLayout() {
        let weatherLabelStackView = UIStackView(arrangedSubviews: [weatherImageView, weatherLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 2
            $0.alignment = .center
        }
        
        let weatherStackView = UIStackView(arrangedSubviews: [weatherLabelStackView, weatherDescriptionLabel]).then {
            $0.axis = .vertical
            $0.spacing = 8
            $0.alignment = .center
        }
        
        let buttonStackView = UIStackView(arrangedSubviews: [registrationButton, recordButton]).then {
            $0.axis = .horizontal
            $0.spacing = 16
            $0.alignment = .center
        }
        
        contentView.addSubview(weeklyDateView)
        contentView.addSubview(weatherStackView)
        contentView.addSubview(reservationLabel)
        contentView.addSubview(buttonStackView)
        
        weeklyDateView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(4)
        }
        
        weatherStackView.snp.makeConstraints {
            $0.top.equalTo(weeklyDateView.snp.bottom).offset(36)
            $0.centerX.equalToSuperview()
        }
        
        reservationLabel.snp.makeConstraints {
            $0.top.equalTo(weatherStackView.snp.bottom).offset(36)
            $0.centerX.equalToSuperview()
        }
        
        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(reservationLabel.snp.bottom).offset(36)
            $0.bottom.equalToSuperview().inset(36)
            $0.centerX.equalToSuperview()
        }
    }
    
    private func generateWeeklyDateView() -> UIStackView {
        let dates = (0..<7).reduce([UIView]()) { array, _ in
            let view = OneDayView()
            return array + [view]
        }
        
        let stackView = UIStackView(arrangedSubviews: dates).then {
            $0.axis = .horizontal
            $0.distribution = .equalSpacing
            $0.alignment = .center
        }
        
        return stackView
    }
}

//MARK: Component
extension HomeWeatherCell {
    class OneDayView: UIStackView {
        let weekdayLabel = UILabel(config: .body12Regular)
        let dateImageView = RoundImageView(image: nil, type: .circle)
        let dateLabel = UILabel(config: .body14Regular)
        
        
        init() {
            super.init(frame: .zero)
            addArrangedSubview(weekdayLabel)
            addArrangedSubview(dateImageView)

            axis = .vertical
            spacing = 8
            alignment = .center
            
            setLayout()
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setLayout() {
            dateImageView.addSubview(dateLabel)
            
            dateImageView.snp.makeConstraints {
                $0.width.height.equalTo(32)
            }
            
            dateLabel.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.width.equalTo(18)
                $0.height.equalTo(20)
            }
        }
    }

}

//MARK: Reactive
extension Reactive where Base: HomeWeatherCell {
    var registerButtonTap: ControlEvent<Void> {
        base.registrationButton.rx.tap
    }
    
    var recordButtonTap: ControlEvent<Void> {
        base.recordButton.rx.tap
    }
}

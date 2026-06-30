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
    private let reservationLabel = UILabel(config: .body16Medium).then {
        $0.numberOfLines = 0
        $0.textAlignment = .center
        $0.lineBreakMode = .byWordWrapping
    }
    
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
        
        weeklyDateView.arrangedSubviews.forEach {
            if let dayView = $0 as? OneDayView {
                dayView.dateImageView.image = nil // 이미지 초기화
                dayView.dateImageView.alpha = 1 // 이미지 투명도 초기화
                dayView.dateBackgroundView.backgroundColor = .clear // 색상 초기화
                dayView.dateLabel.isHidden = false // label isHidden 초기화
            }
        }
    }
}

//MARK: Configure
extension HomeWeatherCell {
    func configure(_ item: HomeCollectionView.WeatherSectionItem) {
        weeklyDateView.arrangedSubviews.enumerated().forEach {
            if let view = $0.element as? OneDayView {
                let date = item.weeklyDate[$0.offset]
                view.weekdayLabel.text = date.weekdayString
                view.dateLabel.text = String(date.day)
                view.dateImageView.image = nil
                view.dateImageView.alpha = 1
                view.dateLabel.isHidden = false
                view.dateBackgroundView.backgroundColor = .clear

                if let imageName = item.programIconNameByDate[date.date] {
                    let isUpcomingProgram = item.upcomingProgramDates.contains(date.date)

                    view.dateImageView.image = UIImage(named: imageName)
                    view.dateImageView.alpha = isUpcomingProgram ? 0.15 : 1
                    view.dateLabel.isHidden = isUpcomingProgram == false
                    view.dateBackgroundView.backgroundColor = isUpcomingProgram ? .primary25 : .primary50
                }
            }
        }
        
        weatherImageView.image = switch item.weather.category {
        case .thunderstorm: .storm
        case .drizzle, .rain: .rain
        case .sun: item.isNight ? .moon : .sun
        case .cloud: .cloud
        case .atmosphere, .wind: .cloudSun
        case .snow: .snow
        case .unknown: .sun
        }
        
        weatherLabel.text = "\(String(format: "%.1f", item.weather.temperature))º"
        weatherDescriptionLabel.text = item.weather.description
        
        reservationLabel.text = item.reservationText
    }
}

//MARK: Layout
extension HomeWeatherCell {
    private func setLayout() {
        let weatherLabelStackView = UIStackView(arrangedSubviews: [weatherImageView, weatherLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 2
            $0.alignment = .center
            
            weatherImageView.setContentHuggingPriority(.required, for: .horizontal)
            weatherImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        
        let weatherStackView = UIStackView(arrangedSubviews: [weatherLabelStackView, weatherDescriptionLabel]).then {
            $0.axis = .vertical
            $0.spacing = 8
            $0.alignment = .center
            
            weatherLabelStackView.setContentHuggingPriority(.required, for: .vertical)
            weatherLabelStackView.setContentCompressionResistancePriority(.required, for: .vertical)
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
            $0.height.equalTo(57)
        }
        
        weatherStackView.snp.makeConstraints {
            $0.top.equalTo(weeklyDateView.snp.bottom).offset(36)
            $0.centerX.equalToSuperview()
        }
        
        reservationLabel.snp.makeConstraints {
            $0.top.equalTo(weatherStackView.snp.bottom).offset(36)
            $0.horizontalEdges.equalToSuperview()
        }
        
        buttonStackView.snp.makeConstraints {
            $0.top.equalTo(reservationLabel.snp.bottom).offset(36)
            $0.bottom.equalToSuperview().inset(36)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(38)
        }
        
        weatherImageView.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
        
        registrationButton.snp.makeConstraints {
            $0.width.equalTo(118)
            $0.height.equalTo(38)
        }
        
        recordButton.snp.makeConstraints {
            $0.width.equalTo(118)
            $0.height.equalTo(38)
        }
    }
    
    private func generateWeeklyDateView() -> UIStackView {
        let dates = (0..<7).reduce([UIView]()) { array, _ in
            let view = OneDayView()
            return array + [view]
        }
        
        let stackView = UIStackView(arrangedSubviews: dates).then {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.alignment = .center
        }
        
        return stackView
    }
}

//MARK: Component
extension HomeWeatherCell {
    class OneDayView: UIStackView {
        let weekdayLabel = UILabel(config: .body12Regular).then {
            $0.textAlignment = .center
        }
        let dateBackgroundView = UIView().then {
            $0.layer.cornerRadius = 16
            $0.clipsToBounds = true
            $0.backgroundColor = .clear
        }
        let dateImageView = RoundImageView(image: nil, type: .circle)
        let dateLabel = UILabel(config: .body14Regular).then {
            $0.textAlignment = .center
        }
        
        init() {
            super.init(frame: .zero)
            addArrangedSubview(dateBackgroundView)
            addArrangedSubview(weekdayLabel)

            axis = .vertical
            spacing = 8
            alignment = .center
            
            setLayout()
            
            dateBackgroundView.setContentHuggingPriority(.required, for: .vertical)
            dateBackgroundView.setContentCompressionResistancePriority(.required, for: .vertical)
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setLayout() {
            dateBackgroundView.addSubview(dateImageView)
            dateBackgroundView.addSubview(dateLabel)
            
            dateBackgroundView.snp.makeConstraints {
                $0.width.height.equalTo(32)
            }
            
            dateImageView.snp.makeConstraints {
                $0.width.height.equalTo(24)
                $0.center.equalToSuperview()
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

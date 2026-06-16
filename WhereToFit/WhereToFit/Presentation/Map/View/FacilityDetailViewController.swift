//
//  FacilityDetailViewController.swift
//  WhereToFit
//
//  Created by 김주희 on 5/27/26.
//

import UIKit
import Kingfisher
import NMapsMap
import SnapKit
import Then

final class FacilityDetailViewController: UIViewController {
    var favoriteButtonTapped: ((FitnessFacility) -> Void)?
    var reservationButtonTapped: ((FitnessFacility) -> Void)?

    private let facility: FitnessFacility
    private let relatedPrograms: [FitnessFacility]
    private let kind: DetailKind
    private let detailView: FacilityDetailView
    private var heroGradientLayer: CAGradientLayer { detailView.heroGradientLayer }
    private var heroImageView: UIImageView { detailView.heroImageView }
    private var backButton: UIButton { detailView.backButton }
    private var favoriteButton: UIButton { detailView.favoriteButton }
    private var contentStackView: UIStackView { detailView.contentStackView }
    private var facilityNameButton: UIButton { detailView.facilityNameButton }
    private var phoneInfoButton: UIButton { detailView.phoneInfoButton }
    private var reservationButton: DesignButton { detailView.reservationButton }
    private var isFavoriteSelected: Bool
    private var isWaitingForReservationReturn = false
    private var didLeaveAppForReservation = false
    private var locationMarker: NMFMarker?
    private var programCards: [FacilityProgramCardView] = []
    private var programCardFacilities: [FitnessFacility] = []
    private let interactivePopGestureDelegate = InteractivePopGestureDelegate()
    private var priceSectionValue: String {
        let listPriceText = FacilityProgramListItemViewModel(facility: facility).priceText
        guard listPriceText == "상세 정보 확인" else {
            return listPriceText
        }

        // 모달에서 "상세 정보 확인"으로 접은 복잡한 가격 문구만 상세에서 원본으로 보여줍니다.
        if let rawPriceText = facility.rawPriceText?.trimmingCharacters(in: .whitespacesAndNewlines),
           rawPriceText.isEmpty == false {
            return rawPriceText
        }

        return listPriceText
    }

    init(facility: FitnessFacility, relatedPrograms: [FitnessFacility] = []) {
        let detailKind: DetailKind = facility.sourceKind == .facility ? .facility : .program
        self.facility = facility
        self.relatedPrograms = Self.uniquePrograms(relatedPrograms)
        self.kind = detailKind
        self.detailView = FacilityDetailView(
            kind: detailKind,
            showsReservationButton: Self.shouldShowReservationButton(facility: facility, kind: detailKind)
        )
        self.isFavoriteSelected = facility.isFavorite
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    private init(facility: FitnessFacility, relatedPrograms: [FitnessFacility], kind: DetailKind) {
        self.facility = facility
        self.relatedPrograms = Self.uniquePrograms(relatedPrograms)
        self.kind = kind
        self.detailView = FacilityDetailView(
            kind: kind,
            showsReservationButton: Self.shouldShowReservationButton(facility: facility, kind: kind)
        )
        self.isFavoriteSelected = facility.isFavorite
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func loadView() {
        view = detailView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureContent()
        configureAppLifecycleObservers()
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(didTapFavoriteButton), for: .touchUpInside)
        facilityNameButton.addTarget(self, action: #selector(didTapFacilityNameButton), for: .touchUpInside)
        phoneInfoButton.addTarget(self, action: #selector(didTapPhoneButton), for: .touchUpInside)
        reservationButton.addTarget(self, action: #selector(didTapReservationButton), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        interactivePopGestureDelegate.attach(to: navigationController)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private static func shouldShowReservationButton(facility: FitnessFacility, kind: DetailKind) -> Bool {
        kind == .program || facility.homepageURL != nil
    }

    private func configureContent() {
        configureHero()
        configureFloatingButtons()
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        switch kind {
        case .program:
            configureProgramDetailContent()
        case .facility:
            configureFacilityDetailContent()
        }
    }

    private func configureHero() {
        let placeholderImageName = kind == .facility
            ? facility.facilityPlaceholderImageName
            : facility.programPlaceholderImageName
        let placeholderImage = UIImage(named: placeholderImageName) ?? UIImage(named: "homeBackground")

        heroImageView.image = placeholderImage
        heroImageView.backgroundColor = color(for: facility.category)
        heroGradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.34).cgColor,
            UIColor.black.withAlphaComponent(0.04).cgColor,
            UIColor.black.withAlphaComponent(0.18).cgColor
        ]
        heroGradientLayer.locations = [0, 0.48, 1]

        if let imageURL = facility.imageURL {
            heroImageView.kf.setImage(
                with: imageURL,
                placeholder: placeholderImage
            )
        }
    }

    private func configureFloatingButtons() {
        configureFloatingButton(backButton, image: UIImage(named: "arrowLeft"))
        updateFavoriteButton()
    }

    private func configureFloatingButton(_ button: UIButton, image: UIImage?) {
        button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        button.tintColor = .gray900
        button.layer.masksToBounds = true
        button.setImage(image?.withTintColor(.gray900, renderingMode: .alwaysOriginal), for: .normal)
    }

    private func updateFavoriteButton() {
        favoriteButton.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        favoriteButton.tintColor = .gray900
        favoriteButton.layer.masksToBounds = true

        let image = if isFavoriteSelected {
            UIImage(named: "heartFilled")?.withRenderingMode(.alwaysOriginal)
        } else {
            UIImage(named: "heart")?.withTintColor(.gray900, renderingMode: .alwaysOriginal)
        }
        favoriteButton.setImage(image, for: .normal)
    }

    private func configureProgramDetailContent() {
        let summaryView = makeProgramSummaryView()
        contentStackView.addArrangedSubview(summaryView)

        contentStackView.addArrangedSubview(makeScheduleSection())
        contentStackView.addArrangedSubview(makePriceSection())
        contentStackView.addArrangedSubview(makeApplicationMethodSection())
        contentStackView.addArrangedSubview(makeDivider())
        contentStackView.addArrangedSubview(makeIntroductionSection())
        contentStackView.addArrangedSubview(makeAmenitiesSection())
        contentStackView.addArrangedSubview(makeParkingSection())
        contentStackView.addArrangedSubview(makeLocationSection())
    }

    private func configureFacilityDetailContent() {
        let summaryView = makeFacilitySummaryView()
        contentStackView.addArrangedSubview(summaryView)
        contentStackView.addArrangedSubview(makeDivider())
        contentStackView.addArrangedSubview(makeOpenProgramsSection())
        contentStackView.addArrangedSubview(makeDivider())
        contentStackView.addArrangedSubview(makeScheduleSection())
        contentStackView.addArrangedSubview(makePriceSection())
        contentStackView.addArrangedSubview(makeApplicationMethodSection())
        contentStackView.addArrangedSubview(makeDivider())
        contentStackView.addArrangedSubview(makeIntroductionSection())
        contentStackView.addArrangedSubview(makeAmenitiesSection())
        contentStackView.addArrangedSubview(makeParkingSection())
        contentStackView.addArrangedSubview(makeDivider())
        contentStackView.addArrangedSubview(makeLocationSection())
    }

    private func makeProgramSummaryView() -> UIView {
        let stackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 8
        }

        let matchingLabel = ColoredLabel(text: "", style: .fill).then {
            $0.text = "매칭률 \(facility.matchingRate)%"
        }
        let matchingContainerView = UIView()
        matchingContainerView.addSubview(matchingLabel)
        let titleLabel = UILabel(text: programTitle, config: .title20Bold, color: .gray900)
        let metaView = makeProgramMetaView()
        let addressRow = makeIconTextRow(
            image: UIImage(named: "locationPin"),
            text: facility.address
        )

        configurePhoneInfoButton()

        stackView.addArrangedSubview(matchingContainerView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(metaView)
        stackView.addArrangedSubview(addressRow)
        stackView.addArrangedSubview(phoneInfoButton)
        stackView.setCustomSpacing(10, after: titleLabel)
        matchingLabel.setContentHuggingPriority(.required, for: .horizontal)
        matchingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        matchingContainerView.snp.makeConstraints {
            $0.height.equalTo(24)
        }
        matchingLabel.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
            $0.height.equalTo(24)
        }

        return stackView
    }

    private func makeFacilitySummaryView() -> UIView {
        let stackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 10
        }

        let titleLabel = UILabel(text: facilityDisplayName, config: .title20Bold, color: .gray900)
        let timeLabel = UILabel(text: compactOperatingHoursText, config: .body14Regular, color: .gray600)
        let addressRow = makeIconTextRow(
            image: UIImage(named: "locationPin"),
            text: facility.address
        )

        configurePhoneInfoButton()

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(timeLabel)
        stackView.addArrangedSubview(addressRow)
        stackView.addArrangedSubview(phoneInfoButton)
        stackView.setCustomSpacing(12, after: timeLabel)

        return stackView
    }

    private func makeProgramMetaView() -> UIView {
        let stackView = UIStackView().then {
            $0.axis = .horizontal
            $0.alignment = .center
            $0.spacing = 8
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: LabelConfiguration.body14Regular.font,
            .foregroundColor: UIColor.gray600,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        facilityNameButton.setAttributedTitle(
            NSAttributedString(string: facilityDisplayName, attributes: attributes),
            for: .normal
        )

        let separatorLabel = UILabel(text: "|", config: .body14Regular, color: .gray400)
        let timeLabel = UILabel(text: compactOperatingHoursText, config: .body14Regular, color: .gray600)

        stackView.addArrangedSubview(facilityNameButton)
        stackView.addArrangedSubview(separatorLabel)
        stackView.addArrangedSubview(timeLabel)
        return stackView
    }

    private func configurePhoneInfoButton() {
        let icon = UIImage(systemName: "phone")?.withTintColor(.gray600, renderingMode: .alwaysOriginal)
        phoneInfoButton.setImage(icon, for: .normal)
        phoneInfoButton.setTitle("  \(facility.phoneNumber)", for: .normal)
        phoneInfoButton.setTitleColor(.gray600, for: .normal)
        phoneInfoButton.titleLabel?.font = LabelConfiguration.body13Regular.font
        phoneInfoButton.tintColor = .gray600
    }

    private func makeIconTextRow(image: UIImage?, text: String) -> UIView {
        let containerView = UIView()
        let imageView = UIImageView(image: image?.withTintColor(.gray600, renderingMode: .alwaysOriginal)).then {
            $0.contentMode = .scaleAspectFit
            $0.tintColor = .gray600
        }
        let label = UILabel(text: text, config: .body13Regular, color: .gray600).then {
            $0.numberOfLines = 0
        }

        containerView.addSubview(imageView)
        containerView.addSubview(label)

        imageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(1)
            $0.leading.equalToSuperview()
            $0.size.equalTo(16)
        }

        label.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(imageView.snp.trailing).offset(8)
        }

        return containerView
    }

    private func makeOpenProgramsSection() -> UIView {
        let sectionStackView = makeSectionStackView(title: "개설 프로그램")
        let scrollView = UIScrollView().then {
            $0.showsHorizontalScrollIndicator = false
            $0.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16)
        }
        let cardStackView = UIStackView().then {
            $0.axis = .horizontal
            $0.spacing = 12
            $0.alignment = .top
        }

        scrollView.addSubview(cardStackView)
        makeProgramCards().forEach { card in
            card.addTarget(self, action: #selector(didTapProgramCard(_:)), for: .touchUpInside)
            cardStackView.addArrangedSubview(card)
        }

        sectionStackView.addArrangedSubview(scrollView)

        scrollView.snp.makeConstraints {
            $0.height.equalTo(200)
        }

        cardStackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.height.equalTo(scrollView.frameLayoutGuide)
        }

        return sectionStackView
    }

    private func makeProgramCards() -> [FacilityProgramCardView] {
        let programs = openProgramFacilities()
        if programs.isEmpty == false {
            programCardFacilities = programs
            let cards = programs.enumerated().map { index, program in
                let card = FacilityProgramCardView(
                    title: program.name,
                    facilityName: facilityDisplayName,
                    matchingRate: program.matchingRate,
                    isIndoor: index != 2,
                    isFavorite: program.isFavorite,
                    imageURL: program.imageURL,
                    placeholderImageName: program.programPlaceholderImageName,
                    tintColor: color(for: program.category)
                )
                card.favoriteButtonTapped = { [weak self] isSelected in
                    self?.updateFavoriteSelection(isSelected)
                }
                return card
            }
            programCards = cards
            return cards
        }

        programCardFacilities = []
        let categoryTitles = fallbackRelatedProgramTitles()
        let cards = categoryTitles.enumerated().map { index, title in
            let card = FacilityProgramCardView(
                title: title,
                facilityName: facilityDisplayName,
                matchingRate: max(55, facility.matchingRate - index * 4),
                isIndoor: index != 2,
                isFavorite: facility.isFavorite,
                imageURL: facility.imageURL,
                placeholderImageName: facility.programPlaceholderImageName,
                tintColor: color(for: facility.category)
            )
            card.favoriteButtonTapped = { [weak self] isSelected in
                self?.updateFavoriteSelection(isSelected)
            }
            return card
        }
        programCards = cards
        return cards
    }

    private func makeScheduleSection() -> UIView {
        let sectionStackView = makeSectionStackView(title: "시설 이용시간")
        let rows = [
            ("평일", weekdayHoursText),
            ("토요일", weekendHoursText),
            ("일요일", weekendHoursText),
            ("휴관일", closedDayText)
        ]
        let rowStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 6
        }

        rows.forEach {
            rowStackView.addArrangedSubview(makeTwoColumnRow(title: $0.0, value: $0.1))
        }

        sectionStackView.addArrangedSubview(makeCard(containing: rowStackView))
        return sectionStackView
    }

    private func makePriceSection() -> UIView {
        let sectionStackView = makeSectionStackView(title: "가격")
        let row = makeTwoColumnRow(
            title: facility.facilityType ?? "\(facility.category.title) 이용",
            value: priceSectionValue,
            valueConfig: .body15
        )
        sectionStackView.addArrangedSubview(makeCard(containing: row))
        return sectionStackView
    }

    private func makeApplicationMethodSection() -> UIView {
        let sectionStackView = makeSectionStackView(title: "신청 방법")
        sectionStackView.addArrangedSubview(makeTextCard(applicationMethodBulletText))
        return sectionStackView
    }

    private func makeIntroductionSection() -> UIView {
        let sectionStackView = makeSectionStackView(title: "시설 소개")
        sectionStackView.addArrangedSubview(makeTextCard(introductionText))
        return sectionStackView
    }

    private func makeAmenitiesSection() -> UIView {
        let sectionStackView = makeSectionStackView(title: "편의 시설")
        let gridStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 14
        }

        for rowValues in amenityTitles.chunked(into: 3) {
            let rowStackView = UIStackView().then {
                $0.axis = .horizontal
                $0.spacing = 24
                $0.distribution = .fillEqually
            }

            rowValues.forEach { title in
                rowStackView.addArrangedSubview(makeAmenityView(title: title))
            }

            (0..<(3 - rowValues.count)).forEach { _ in
                rowStackView.addArrangedSubview(UIView())
            }
            gridStackView.addArrangedSubview(rowStackView)
        }

        sectionStackView.addArrangedSubview(gridStackView)
        return sectionStackView
    }

    private func makeParkingSection() -> UIView {
        let sectionStackView = makeSectionStackView(title: "주차")
        sectionStackView.addArrangedSubview(makeTextCard(parkingText, numberOfLines: 0))
        return sectionStackView
    }

    private func makeLocationSection() -> UIView {
        let sectionStackView = makeSectionStackView(title: "위치")
        let mapView = makeLocationMapView()
        sectionStackView.addArrangedSubview(mapView)
        mapView.snp.makeConstraints {
            $0.height.equalTo(mapView.snp.width)
        }
        return sectionStackView
    }

    private func makeSectionStackView(title: String) -> UIStackView {
        let titleLabel = UILabel(text: title, config: .title16, color: .gray900)
        return UIStackView(arrangedSubviews: [titleLabel]).then {
            $0.axis = .vertical
            $0.spacing = 14
        }
    }

    private func makeTwoColumnRow(
        title: String,
        value: String,
        valueConfig: LabelConfiguration = .body14Regular
    ) -> UIView {
        let containerView = UIView()
        let titleLabel = UILabel(text: title, config: .body14Regular, color: .gray600)
        let valueLabel = UILabel(text: value, config: valueConfig, color: .gray900).then {
            $0.textAlignment = .right
            $0.numberOfLines = 0
        }

        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)

        titleLabel.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
        }

        valueLabel.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }

        return containerView
    }

    private func makeCard(containing content: UIView, insets: UIEdgeInsets = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)) -> UIView {
        let containerView = UIView().then {
            $0.backgroundColor = .gray50
            $0.layer.cornerRadius = 10
            $0.layer.masksToBounds = true
        }
        containerView.addSubview(content)
        content.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(insets)
        }
        return containerView
    }

    private func makeTextCard(_ text: String, numberOfLines: Int = 0) -> UIView {
        let label = UILabel(text: text, config: .body13Regular, color: .gray600).then {
            $0.numberOfLines = numberOfLines
        }
        return makeCard(containing: label)
    }

    private func makeAmenityView(title: String) -> UIView {
        let containerView = UIView()
        let iconContainerView = UIView().then {
            $0.backgroundColor = .primary25
            $0.layer.cornerRadius = 8
            $0.layer.masksToBounds = true
        }
        let imageView = UIImageView(image: amenityIcon(for: title)).then {
            $0.contentMode = .scaleAspectFit
        }
        let label = UILabel(text: title, config: .body12Regular, color: .gray600).then {
            $0.textAlignment = .center
            $0.numberOfLines = 2
        }

        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(imageView)
        containerView.addSubview(label)

        iconContainerView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.size.equalTo(48)
        }

        imageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(24)
        }

        label.snp.makeConstraints {
            $0.top.equalTo(iconContainerView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        return containerView
    }

    private func makeLocationMapView() -> UIView {
        let containerView = UIView().then {
            $0.clipsToBounds = true
        }
        let naverMapView = NMFNaverMapView().then {
            $0.showCompass = false
            $0.showScaleBar = false
            $0.showZoomControls = false
            $0.showLocationButton = false
            $0.mapView.isScrollGestureEnabled = true
            $0.mapView.isZoomGestureEnabled = true
            $0.mapView.isTiltGestureEnabled = false
            $0.mapView.isStopGestureEnabled = true
        }

        containerView.addSubview(naverMapView)
        naverMapView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        let coordinate = NMGLatLng(
            lat: facility.coordinate.latitude,
            lng: facility.coordinate.longitude
        )
        let marker = NMFMarker(position: coordinate)
        if let markerImage = UIImage(named: "locationPinFilled")?.withTintColor(.primary400, renderingMode: .alwaysOriginal) {
            marker.iconImage = NMFOverlayImage(image: markerImage)
            marker.width = 30
            marker.height = 30
        }
        marker.mapView = naverMapView.mapView
        locationMarker = marker

        DispatchQueue.main.async {
            let cameraUpdate = NMFCameraUpdate(scrollTo: coordinate, zoomTo: 12)
            naverMapView.mapView.moveCamera(cameraUpdate)
        }

        return containerView
    }

    private func makeDivider() -> UIView {
        UIView().then {
            $0.backgroundColor = .gray100
            $0.snp.makeConstraints { make in
                make.height.equalTo(1)
            }
        }
    }

    private func amenityIcon(for title: String) -> UIImage? {
        let assetName: String
        if title.contains("와이파이") {
            assetName = "wifi"
        } else if title.contains("주차") {
            assetName = "Parking"
        } else if title.contains("탈의") || title.contains("샤워") {
            assetName = "towel"
        } else if title.contains("CCTV") || title.contains("카메라") {
            assetName = "cctv"
        } else if title.contains("유아") {
            assetName = "Children"
        } else if title.contains("수영") {
            assetName = "Clothe"
        } else {
            assetName = "other"
        }

        return UIImage(named: assetName)?.withRenderingMode(.alwaysOriginal)
    }

    private func configureAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    private var programTitle: String {
        if facility.sourceKind == .program {
            return facility.name
        }

        switch facility.category {
        case .swimming: return "수영 클래스"
        case .tennis: return "테니스장 대관"
        case .soccer: return "축구장 대관"
        case .futsal: return "풋살장 대관"
        case .basketball: return "농구장 대관"
        case .baseball: return "야구장 대관"
        case .yoga: return "요가 클래스"
        case .pilates: return "필라테스 클래스"
        case .gym: return "헬스장 자유 이용"
        default: return "\(facility.category.title) 프로그램"
        }
    }

    private var facilityDisplayName: String {
        facility.locationName?.isEmpty == false ? facility.locationName ?? facility.name : facility.name
    }

    private var compactOperatingHoursText: String {
        if facility.sourceKind == .program {
            return "\(facility.dayText) \(hourText(separator: "-"))"
        }

        return "월~금 \(hourText(separator: "-"))"
    }

    private var weekdayHoursText: String {
        extractHours(prefix: "평일") ?? hourText(separator: " ~ ")
    }

    private var weekendHoursText: String {
        extractHours(prefix: "주말") ?? hourText(separator: " ~ ")
    }

    private var closedDayText: String {
        facility.operatingHoursText
            .components(separatedBy: .newlines)
            .first { $0.contains("휴관일") }
            .map { $0.replacingOccurrences(of: "휴관일", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { $0.isEmpty ? nil : $0 } ?? "공휴일"
    }

    private var applicationMethodBulletText: String {
        let values = facility.applicationMethodText
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        let lines = values.isEmpty ? ["예약 사이트를 통해 신청 가능"] : values
        return lines.map { "* \($0)" }.joined(separator: "\n")
    }

    private var introductionText: String {
        let values = [facility.introduction, facility.description]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false && $0 != "시설 소개 정보 없음" }

        return values.isEmpty ? "\(facilityDisplayName) 시설 소개 정보가 준비 중입니다." : values.joined(separator: "\n\n")
    }

    private var parkingText: String {
        facility.parkingInfo == "주차 정보 없음" ? "무료 주차 지원" : facility.parkingInfo
    }

    private var amenityTitles: [String] {
        let values = facility.amenities
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        if values.isEmpty == false {
            return Array(values.prefix(6))
        }

        switch facility.category {
        case .swimming:
            return ["와이파이", "주차", "탈의실", "CCTV", "유아 편의시설", "수영복"]
        default:
            return ["와이파이", "주차", "탈의실", "CCTV", "유아 편의시설", "샤워실"]
        }
    }

    private func openProgramFacilities() -> [FitnessFacility] {
        guard let sourceFacilityID = facility.sourceFacilityID else {
            return facility.sourceKind == .program ? [facility] : []
        }

        let candidates = relatedPrograms + [facility]
        let programs = candidates.filter {
            $0.sourceKind == .program && $0.sourceFacilityID == sourceFacilityID
        }

        return Self.uniquePrograms(programs)
    }

    private func fallbackRelatedProgramTitles() -> [String] {
        switch facility.category {
        case .swimming:
            return ["수영"]
        case .tennis:
            return ["테니스장 대관", "테니스 레슨"]
        case .soccer:
            return ["축구장 대관"]
        case .futsal:
            return ["풋살장 대관"]
        default:
            return [programTitle]
        }
    }

    private static func uniquePrograms(_ programs: [FitnessFacility]) -> [FitnessFacility] {
        var seenKeys = Set<String>()
        return programs.filter { program in
            let key = program.sourceProgramID.map { "program-\($0)" } ?? program.id
            return seenKeys.insert(key).inserted
        }
    }

    private func hourText(separator: String) -> String {
        let start = String(format: "%02d:00", facility.availableTimeRange.startHour)
        let endHour = facility.availableTimeRange.endHour == 24 ? "24:00" : String(format: "%02d:00", facility.availableTimeRange.endHour)
        return "\(start)\(separator)\(endHour)"
    }

    private func extractHours(prefix: String) -> String? {
        facility.operatingHoursText
            .components(separatedBy: .newlines)
            .first { $0.hasPrefix(prefix) }
            .map { $0.replacingOccurrences(of: prefix, with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.replacingOccurrences(of: "-", with: " ~ ") }
    }

    private func color(for category: FacilityCategory) -> UIColor {
        switch category {
        case .soccer, .futsal, .baseball, .floorball: return .systemGreen
        case .basketball, .volleyball, .badminton, .tableTennis, .squash, .racquetball, .pickleball, .gateball, .billiards, .bowling: return .systemRed
        case .gym, .healthPT, .bodybuilding, .gx, .trx, .circuitTraining, .spinningBike, .fitBalance, .womensCircuitExercise, .running, .jogging, .athletics, .cycling, .runBike, .triathlon, .lifeSports, .childSports, .infantSports, .jumpRope, .womensHealthClass, .bodySkillRelease, .boccia: return .systemOrange
        case .yoga, .powerYoga, .pilates, .snpe, .dance, .lineDance, .broadcastDance, .bellyDance, .sportsDance, .zumbaDance, .dietDance, .ballet, .traditionalDance, .koreanDance, .gymnastics, .kuksundo, .koreanQigong, .taiChi, .lifeGymnastics, .stretching, .aerobics, .dietRobics, .seniorRobics, .taebo, .jumpingDiet, .jumpingTrampoline: return .systemPink
        case .swimming, .survivalSwimming, .aquaticHealthGymnastics, .aquaRobics, .aquaWalking, .aquathlon, .artisticSwimming, .scubaDiving: return .systemTeal
        case .tennis, .golf, .parkGolf: return .systemYellow
        case .climbing, .sBoard, .hiking: return .systemIndigo
        case .skating, .speedSkating, .figureSkating, .skiing, .rollerSkating: return .systemCyan
        case .kendo, .boxing, .judo, .taekwondo, .taekkyeon, .fencing, .traditionalArchery: return .systemPurple
        case .multipurpose: return .systemGray4
        }
    }

    @objc private func didTapBackButton() {
        if let navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @objc private func didTapFavoriteButton() {
        updateFavoriteSelection(isFavoriteSelected == false)
    }

    private func updateFavoriteSelection(_ isSelected: Bool) {
        guard isFavoriteSelected != isSelected else { return }
        isFavoriteSelected = isSelected
        updateFavoriteButton()
        programCards.forEach { $0.setFavoriteSelected(isSelected) }
        favoriteButtonTapped?(facility)
    }

    @objc private func didTapFacilityNameButton() {
        guard kind == .program else { return }
        let viewController = FacilityDetailViewController(
            facility: facility,
            relatedPrograms: relatedPrograms,
            kind: .facility
        )
        viewController.favoriteButtonTapped = favoriteButtonTapped
        viewController.reservationButtonTapped = reservationButtonTapped
        if let navigationController {
            navigationController.pushViewController(viewController, animated: true)
        } else {
            present(viewController, animated: true)
        }
    }

    @objc private func didTapProgramCard(_ sender: FacilityProgramCardView) {
        let selectedProgram: FitnessFacility
        if let index = programCards.firstIndex(where: { $0 === sender }),
           programCardFacilities.indices.contains(index) {
            selectedProgram = programCardFacilities[index]
        } else {
            selectedProgram = facility
        }

        let viewController = FacilityDetailViewController(
            facility: selectedProgram,
            relatedPrograms: relatedPrograms,
            kind: .program
        )
        viewController.favoriteButtonTapped = favoriteButtonTapped
        viewController.reservationButtonTapped = reservationButtonTapped
        if let navigationController {
            navigationController.pushViewController(viewController, animated: true)
        } else {
            present(viewController, animated: true)
        }
    }

    @objc private func didTapPhoneButton() {
        let digits = facility.phoneNumber.filter { $0.isNumber }
        guard digits.isEmpty == false,
              let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func didTapReservationButton() {
        isWaitingForReservationReturn = true
        didLeaveAppForReservation = false
        reservationButtonTapped?(facility)
    }

    @objc private func handleWillResignActive() {
        guard isWaitingForReservationReturn else { return }
        didLeaveAppForReservation = true
    }

    @objc private func handleDidBecomeActive() {
        guard isWaitingForReservationReturn, didLeaveAppForReservation else { return }
        isWaitingForReservationReturn = false
        didLeaveAppForReservation = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.presentReservationCompletionModal()
        }
    }

    private func presentReservationCompletionModal() {
        guard presentedViewController == nil, view.window != nil else { return }
        present(ReservationCompletionViewController(), animated: true)
    }
}

private final class FacilityProgramCardView: UIControl {
    var favoriteButtonTapped: ((Bool) -> Void)?

    private let imageView = ProgramImageView(image: nil)
    private let matchLabel = ColoredLabel(text: "", style: .fill)
    private let placeLabel = ColoredLabel(text: "", style: .border)
    private let nameLabel = UILabel(text: "", config: .body16Medium, color: .gray900).then {
        $0.numberOfLines = 1
    }
    private let facilityLabel = UILabel(text: "", config: .body12Regular, color: .gray600).then {
        $0.numberOfLines = 1
    }

    init(
        title: String,
        facilityName: String,
        matchingRate: Int,
        isIndoor: Bool,
        isFavorite: Bool,
        imageURL: URL?,
        placeholderImageName: String,
        tintColor: UIColor
    ) {
        super.init(frame: .zero)
        imageView.backgroundColor = tintColor
        let placeholderImage = UIImage(named: placeholderImageName) ?? UIImage(named: "homeBackground")
        imageView.image = placeholderImage
        if let imageURL {
            imageView.kf.setImage(with: imageURL, placeholder: placeholderImage)
        }
        matchLabel.text = "매칭률\(matchingRate)%"
        placeLabel.text = isIndoor ? "실내" : "야외"
        nameLabel.text = title
        facilityLabel.text = facilityName
        imageView.favoriteButton.isSelected = isFavorite
        imageView.favoriteButton.addTarget(self, action: #selector(didTapFavoriteButton), for: .touchUpInside)
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.6 : 1
        }
    }

    private func configureLayout() {
        let badgeStackView = UIStackView(arrangedSubviews: [matchLabel, placeLabel]).then {
            $0.axis = .horizontal
            $0.spacing = 4
            $0.alignment = .center
        }

        addSubview(imageView)
        addSubview(badgeStackView)
        addSubview(nameLabel)
        addSubview(facilityLabel)

        snp.makeConstraints {
            $0.width.equalTo(132)
        }

        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(132)
        }

        badgeStackView.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(8)
            $0.leading.trailing.lessThanOrEqualToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(badgeStackView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
        }

        facilityLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    @objc private func didTapFavoriteButton() {
        imageView.favoriteButton.isSelected.toggle()
        favoriteButtonTapped?(imageView.favoriteButton.isSelected)
    }

    func setFavoriteSelected(_ isSelected: Bool) {
        imageView.favoriteButton.isSelected = isSelected
    }
}

private final class ReservationCompletionViewController: UIViewController {
    private let handleView = UIView().then {
        $0.backgroundColor = .gray200
        $0.layer.cornerRadius = 2
    }

    private let closeButton = UIButton(configuration: .plain()).then {
        $0.setImage(UIImage(named: "close")?.withTintColor(.gray600, renderingMode: .alwaysOriginal), for: .normal)
        $0.tintColor = .gray600
    }

    private let iconImageView = UIImageView(image: .roundCheck).then {
        $0.contentMode = .scaleAspectFit
    }

    private let titleLabel = UILabel(text: "예약 신청을 완료했나요?", config: .title18, color: .gray900).then {
        $0.textAlignment = .center
    }

    private let descriptionLabel = UILabel(
        text: "외부 예약 페이지에서 신청을 마친 뒤\n결과를 선택해 주세요.",
        config: .body13Regular,
        color: .gray600
    ).then {
        $0.textAlignment = .center
        $0.numberOfLines = 2
    }

    private let incompleteButton = DesignButton(config: .mediumBorderBlue).then {
        $0.title = "미완료"
    }

    private let completeButton = DesignButton(config: .mediumFilledBlue).then {
        $0.title = "완료"
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheetPresentationController {
            sheetPresentationController.detents = [
                .custom(identifier: .init("reservationCompletion")) { _ in 300 }
            ]
            sheetPresentationController.prefersGrabberVisible = false
            sheetPresentationController.preferredCornerRadius = 16
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureLayout()
        closeButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        incompleteButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
        completeButton.addTarget(self, action: #selector(dismissModal), for: .touchUpInside)
    }

    private func configureLayout() {
        let buttonStackView = UIStackView(arrangedSubviews: [incompleteButton, completeButton]).then {
            $0.axis = .horizontal
            $0.spacing = 12
            $0.distribution = .fillEqually
        }

        view.addSubview(handleView)
        view.addSubview(closeButton)
        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(buttonStackView)

        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(72)
            $0.height.equalTo(4)
        }

        closeButton.snp.makeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(32)
        }

        iconImageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(58)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(64)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        buttonStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(18)
            $0.height.equalTo(48)
        }
    }

    @objc private func dismissModal() {
        dismiss(animated: true)
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

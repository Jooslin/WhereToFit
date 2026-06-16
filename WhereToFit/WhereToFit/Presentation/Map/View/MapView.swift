//
//  MapView.swift
//  WhereToFit
//
//  Created by 김주희 on 6/8/26.
//

import UIKit
import NMapsMap
import SnapKit
import Then

// MARK: - 지도 탭 View
final class MapView: UIView {
    private enum Metric {
        static let currentLocationButtonBottomSpacing: CGFloat = 16
    }

    // MARK: - UI Components
    let searchTextField = SearchBar(placeholder: "지도에서 동, 역 이름으로 검색하기")

    // 검색어 자동 완성 결과 테이블 뷰
    let searchSuggestionTableView = UITableView().then {
        $0.register(SearchSuggestionCell.self, forCellReuseIdentifier: SearchSuggestionCell.reuseIdentifier)
        $0.rowHeight = SearchSuggestionCell.rowHeight
        $0.isHidden = true
        $0.backgroundColor = .systemBackground
        $0.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.gray200.cgColor
    }

    // 네이버 지도 화면
    let naverMapView = NMFNaverMapView()

    // TODO: - 디버깅용 배포시 삭제
    let missingKeyView = UILabel().then {
        $0.text = "Naver Map Key 필요"
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textAlignment = .center
        $0.backgroundColor = .systemGray6
        $0.textColor = .secondaryLabel
    }

    let currentLocationButton = CircularIconButton(
        image: .crosshair.withTintColor(.gray600, renderingMode: .alwaysOriginal)
    )

    let bottomPanelView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // 위쪽 양옆 모서리만 둥글게
        $0.applyShadow(color: .black, opacity: 0.14, offset: CGSize(width: 0, height: -2), radius: 8)
    }

    // 시설물 목록 테이블 뷰
    let tableView = UITableView().then {
        $0.register(FacilityListCell.self, forCellReuseIdentifier: FacilityListCell.reuseIdentifier)
        $0.rowHeight = 128
        $0.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    let loadingIndicatorView = UIActivityIndicatorView(style: .medium)

    let emptyStateLabel = UILabel(text: "프로그램 정보를 불러오는 중입니다.", config: .body13Medium, color: .gray500).then {
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }


    // MARK: - Filter Buttons
    let allFilterButton = UIButton(type: .system)
    let aiButton = FilterChipButton()
    let categoryButton = FilterChipButton()
    let dayButton = FilterChipButton()
    let timeButton = FilterChipButton()
    let priceButton = FilterChipButton()

    private let filterScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
    }

    private let filterStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .center
    }

    // 하단 패널 손잡이 뷰
    private let bottomPanelGrabberView = UIView().then {
        $0.backgroundColor = .gray100
        $0.layer.cornerRadius = 2
    }

    // 동적으로 (하단 패널, 검색 자동완성 창)높이 조절하기 위한 제약조건 변수
    private var bottomPanelHeightConstraint: Constraint?
    private var searchSuggestionHeightConstraint: Constraint?


    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        configureLayout() // 뷰 얹기, 제약조건 설정
        configureFilterButtons() // 필터 버튼 디자인, 스택뷰 추가
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - Public Methods
    // 하단 패널 높이 조정 메서드
    func updateBottomPanelHeight(_ height: CGFloat) {
        bottomPanelHeightConstraint?.update(offset: height)
    }

    // 검색 자동완성 창 높이 조정 메서드
    func updateSearchSuggestionHeight(_ height: CGFloat) {
        searchSuggestionHeightConstraint?.update(offset: height)
    }

    // 필터 적용 여부에 따른 버튼 상태 업데이트 메서드
    func updateFilterButtons(_ filter: FacilityFilter) {
        updateTopChip(aiButton, isPressed: filter.isAIRecommendationEnabled)
        updateModalButton(
            categoryButton,
            title: categoryTitle(for: filter.categories),
            isPressed: filter.categories.isEmpty == false
        )
        updateModalButton(
            dayButton,
            title: dayTitle(for: filter.days),
            isPressed: filter.days.isEmpty == false
        )
        updateModalButton(
            timeButton,
            title: timeTitle(for: filter.timeSlots),
            isPressed: filter.timeSlots.isEmpty == false
        )
        updateModalButton(
            priceButton,
            title: priceTitle(
                minimumPrice: filter.minimumPrice,
                maximumPrice: filter.maximumPrice
            ),
            isPressed: filter.minimumPrice != nil || filter.maximumPrice != nil
        )
    }

    private func configureLayout() {
        addSubview(naverMapView)
        addSubview(missingKeyView)
        addSubview(searchTextField)
        addSubview(filterScrollView)
        filterScrollView.addSubview(filterStackView)
        addSubview(currentLocationButton)
        addSubview(bottomPanelView)
        bottomPanelView.addSubview(bottomPanelGrabberView)
        bottomPanelView.addSubview(tableView)
        bottomPanelView.addSubview(loadingIndicatorView)
        bottomPanelView.addSubview(emptyStateLabel)
        addSubview(searchSuggestionTableView)

        searchTextField.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }

        filterScrollView.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(42)
        }

        filterStackView.snp.makeConstraints {
            $0.edges.equalTo(filterScrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            $0.height.equalTo(filterScrollView.frameLayoutGuide)
        }

        searchSuggestionTableView.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(searchTextField)
            searchSuggestionHeightConstraint = $0.height.equalTo(0).constraint
        }

        naverMapView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        missingKeyView.snp.makeConstraints {
            $0.edges.equalTo(naverMapView)
        }

        currentLocationButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(bottomPanelView.snp.top).offset(-Metric.currentLocationButtonBottomSpacing)
            $0.size.equalTo(44)
        }

        bottomPanelView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            bottomPanelHeightConstraint = $0.height.equalTo(180).constraint
        }

        bottomPanelGrabberView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(72)
            $0.height.equalTo(4)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(bottomPanelGrabberView.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        loadingIndicatorView.snp.makeConstraints {
            $0.center.equalTo(emptyStateLabel)
        }

        emptyStateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(48)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
    }

    func maximumBottomPanelHeight(currentLocationButtonMinimumGap: CGFloat) -> CGFloat? {
        let filterBottomY = filterScrollView.frame.maxY
        let currentLocationButtonHeight = currentLocationButton.bounds.height

        guard bounds.height > 0,
              filterBottomY > 0,
              currentLocationButtonHeight > 0 else {
            return nil
        }

        let minimumPanelTopY = filterBottomY
            + currentLocationButtonMinimumGap
            + currentLocationButtonHeight
            + Metric.currentLocationButtonBottomSpacing

        return bounds.height - minimumPanelTopY
    }

    private func configureFilterButtons() {
        configureIconChip(allFilterButton, image: UIImage(named: "slider"))
        filterStackView.addArrangedSubview(allFilterButton)

        configureChip(aiButton, title: "AI 추천")
        filterStackView.addArrangedSubview(aiButton)

        configureModalButton(categoryButton, title: "운동종목")
        configureModalButton(dayButton, title: "요일")
        configureModalButton(timeButton, title: "시간")
        configureModalButton(priceButton, title: "가격")

        [categoryButton, dayButton, timeButton, priceButton].forEach {
            filterStackView.addArrangedSubview($0)
        }
    }

    private func configureChip(_ button: FilterChipButton, title: String) {
        button.configure(title: title, trailingIcon: nil)
        button.layer.borderWidth = 1
        updateTopChip(button, isPressed: false)
    }

    private func configureIconChip(_ button: UIButton, image: UIImage?) {
        button.configuration = nil
        button.setImage(makeFilterIconImage(from: image), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .gray900
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        updateTopChip(button, isPressed: false)
        button.snp.makeConstraints {
            $0.width.equalTo(32)
            $0.height.equalTo(32)
        }
    }

    private func makeFilterIconImage(from image: UIImage?) -> UIImage? {
        guard let image else { return nil }

        return makeTemplateImage(from: image, size: CGSize(width: 20, height: 20))
    }

    private func configureModalButton(_ button: FilterChipButton, title: String) {
        button.layer.borderWidth = 1
        updateModalButton(button, title: title, isPressed: false)
    }

    private func updateModalButton(_ button: FilterChipButton, title: String, isPressed: Bool) {
        button.configure(
            title: title,
            trailingIcon: makeTemplateImage(
                from: UIImage(named: "arrowDown"),
                size: CGSize(width: 16, height: 16),
                tintColor: isPressed ? .primary600 : .gray900
            )
        )
        updateTopChip(button, isPressed: isPressed)
    }

    private func makeTemplateImage(
        from image: UIImage?,
        size: CGSize,
        tintColor: UIColor = .gray900
    ) -> UIImage? {
        guard let image else { return nil }

        return UIGraphicsImageRenderer(size: size).image { _ in
            image.withTintColor(tintColor, renderingMode: .alwaysOriginal)
                .draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func updateTopChip(_ button: UIButton, isPressed: Bool) {
        let titleColor = isPressed ? UIColor.primary600 : UIColor.gray900
        button.backgroundColor = isPressed ? .primary25 : .systemBackground
        button.tintColor = titleColor
        button.isSelected = isPressed
        button.setTitleColor(titleColor, for: .normal)
        button.setTitleColor(titleColor, for: .selected)
        button.setTitleColor(titleColor, for: .highlighted)
        button.layer.borderColor = (isPressed ? UIColor.primary200 : UIColor.gray200).cgColor
    }

    private func categoryTitle(for categories: Set<FacilityCategory>) -> String {
        let selectedCategories = FacilityCategory.allCases.filter { categories.contains($0) }
        guard let firstCategory = selectedCategories.first else {
            return "운동종목"
        }

        guard selectedCategories.count > 1 else {
            return firstCategory.title
        }

        return "\(firstCategory.title) 외 \(selectedCategories.count - 1)"
    }

    private func dayTitle(for days: Set<DayOfWeek>) -> String {
        let selectedDays = DayOfWeek.allCases.filter { days.contains($0) }
        guard selectedDays.isEmpty == false else {
            return "요일"
        }

        return selectedDays.map(\.title).joined(separator: "·")
    }

    private func timeTitle(for timeSlots: Set<TimeSlot>) -> String {
        let selectedTimeSlots = TimeSlot.allCases.filter { timeSlots.contains($0) }
        guard let firstTimeSlot = selectedTimeSlots.first else {
            return "시간"
        }

        guard selectedTimeSlots.count > 1 else {
            return firstTimeSlot.filterTitle
        }

        return "\(firstTimeSlot.filterTitle) 외 \(selectedTimeSlots.count - 1)"
    }

    private func priceTitle(minimumPrice: Int?, maximumPrice: Int?) -> String {
        switch (minimumPrice, maximumPrice) {
        case let (.some(minimumPrice), .some(maximumPrice)):
            return "\(formatPrice(minimumPrice)) ~ \(formatPrice(maximumPrice))"
        case let (.some(minimumPrice), .none):
            return "\(formatPrice(minimumPrice)) 이상"
        case let (.none, .some(maximumPrice)):
            return "\(formatPrice(maximumPrice)) 이하"
        case (.none, .none):
            return "가격"
        }
    }

    private func formatPrice(_ price: Int) -> String {
        "\(price.formatted())원"
    }
}

final class SearchSuggestionCell: UITableViewCell {
    static let reuseIdentifier = "SearchSuggestionCell"
    static let rowHeight: CGFloat = 64

    private let iconBackgroundView = UIView().then {
        $0.backgroundColor = .primary25
        $0.layer.cornerRadius = 16
    }

    private let iconImageView = UIImageView().then {
        $0.image = UIImage(named: "locationPin")?.withTintColor(.primary400, renderingMode: .alwaysOriginal)
        $0.contentMode = .scaleAspectFit
    }

    private let titleLabel = UILabel(text: "", config: .body14Medium, color: .gray900)

    private let subtitleLabel = UILabel(text: "", config: .body12Regular, color: .gray600).then {
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let distanceLabel = UILabel(text: "", config: .body12Regular, color: .gray500).then {
        $0.textAlignment = .right
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .systemBackground
        contentView.backgroundColor = .systemBackground
        contentView.addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(distanceLabel)

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        distanceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        iconBackgroundView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }

        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(24)
        }

        distanceLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(15)
            $0.trailing.equalToSuperview().inset(16)
            $0.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.leading.equalTo(iconBackgroundView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(distanceLabel.snp.leading).offset(-12)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(3)
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(distanceLabel.snp.leading).offset(-12)
            $0.bottom.lessThanOrEqualToSuperview().inset(8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with suggestion: MapSearchSuggestion) {
        titleLabel.text = suggestion.title
        subtitleLabel.text = suggestion.subtitle
        distanceLabel.text = suggestion.distanceText
    }
}

extension UIView {
    func applyShadow(color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
    }
}

final class FilterChipButton: UIButton {
    private let horizontalPadding: CGFloat = 12
    private let verticalPadding: CGFloat = 6
    private let iconSize = CGSize(width: 16, height: 16)
    private let iconSpacing: CGFloat = 4
    private var hasTrailingIcon = false

    override init(frame: CGRect) {
        super.init(frame: .zero)
        titleLabel?.font = LabelConfiguration.body13Regular.font
        setTitleColor(.gray900, for: .normal)
        tintColor = .gray900
        contentHorizontalAlignment = .left
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let titleSize = measuredTitleSize()
        let iconWidth = hasTrailingIcon ? iconSize.width + iconSpacing : 0
        return CGSize(
            width: ceil(horizontalPadding + titleSize.width + iconWidth + horizontalPadding),
            height: ceil(verticalPadding + max(titleSize.height, hasTrailingIcon ? iconSize.height : 0) + verticalPadding)
        )
    }

    func configure(title: String, trailingIcon: UIImage?) {
        hasTrailingIcon = trailingIcon != nil
        setTitle(title, for: .normal)
        setImage(trailingIcon, for: .normal)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        layer.cornerCurve = .circular
        clipsToBounds = true

        let titleSize = measuredTitleSize()
        let titleY = (bounds.height - titleSize.height) / 2
        titleLabel?.frame = CGRect(
            x: horizontalPadding,
            y: titleY,
            width: titleSize.width,
            height: titleSize.height
        )

        guard hasTrailingIcon else {
            imageView?.frame = .zero
            return
        }

        imageView?.frame = CGRect(
            x: horizontalPadding + titleSize.width + iconSpacing,
            y: (bounds.height - iconSize.height) / 2,
            width: iconSize.width,
            height: iconSize.height
        )
    }

    private func measuredTitleSize() -> CGSize {
        guard let title = currentTitle, title.isEmpty == false else {
            return .zero
        }

        return (title as NSString).size(withAttributes: [
            .font: LabelConfiguration.body13Regular.font
        ])
    }
}

private extension TimeSlot {
    var filterTitle: String {
        switch self {
        case .dawn: return "새벽(7시 이전)"
        case .morning: return "아침(7~9시)"
        case .forenoon: return "오전(9~12시)"
        case .afternoon: return "오후(12~17시)"
        case .evening: return "저녁(17~21시)"
        case .night: return "21시 이후"
        }
    }
}

final class CircularIconButton: UIButton {
    private let iconSize: CGSize

    init(image: UIImage?, iconSize: CGSize = CGSize(width: 24, height: 24)) {
        self.iconSize = iconSize
        super.init(frame: .zero)
        configuration = nil
        setImage(image, for: .normal)
        imageView?.contentMode = .scaleAspectFit
        backgroundColor = .systemBackground
        layer.cornerCurve = .circular
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray200.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
}

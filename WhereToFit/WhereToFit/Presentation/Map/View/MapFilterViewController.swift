//
//  MapFilterViewController.swift
//  WhereToFit
//
//  Created by 김주희 on 5/31/26.
//

import UIKit
import RxCocoa
import RxSwift
import SnapKit
import Then

enum MapFilterMode {
    case all
    case category
    case schedule
    case price
}

enum MapFilterCategorySelectionBehavior {
    case multiple
    case single
}

private struct CategoryGroup {
    let title: String
    let categories: [FacilityCategory]
}

private struct CategorySelectionOption {
    let title: String
    let categories: Set<FacilityCategory>
}

private final class FilterOptionChipButton: UIButton {
    private let horizontalPadding: CGFloat = 12
    private let verticalPadding: CGFloat = 6

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.font = LabelConfiguration.body13Regular.font
        titleLabel?.lineBreakMode = .byTruncatingTail
        layer.cornerRadius = 14
        layer.borderWidth = 1
        backgroundColor = .systemBackground
        setTitleColor(.gray900, for: .normal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let titleSize = measuredTitleSize()
        return CGSize(
            width: ceil(horizontalPadding + titleSize.width + horizontalPadding),
            height: ceil(verticalPadding + titleSize.height + verticalPadding)
        )
    }

    func setSelectedStyle(_ isSelected: Bool) {
        backgroundColor = isSelected ? .primary25 : .systemBackground
        setTitleColor(isSelected ? .primary600 : .gray900, for: .normal)
        layer.borderColor = (isSelected ? UIColor.primary200 : UIColor.gray200).cgColor
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleSize = measuredTitleSize()
        return CGRect(
            x: horizontalPadding,
            y: (contentRect.height - titleSize.height) / 2,
            width: titleSize.width,
            height: titleSize.height
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

private final class CategoryGroupControl: UIControl {
    private let titleLabel = UILabel(config: .body14Regular)

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 8
        addSubview(titleLabel)

        titleLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, count: Int, isSelected: Bool) {
        backgroundColor = isSelected ? .gray25 : .clear
        let titleColor = isSelected ? UIColor.gray900 : UIColor.gray500
        let text = count > 0 ? "\(title) \(count)" : title
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: LabelConfiguration.body14Regular.font,
                .foregroundColor: titleColor
            ]
        )

        if count > 0,
           let range = text.range(of: "\(count)", options: .backwards) {
            attributedText.addAttributes(
                [
                    .font: LabelConfiguration.body14Regular.font,
                    .foregroundColor: UIColor.primary400
                ],
                range: NSRange(range, in: text)
            )
        }
        titleLabel.attributedText = attributedText
    }
}

private final class CategoryOptionRow: UIControl {
    private let checkBoxView = UIView()
    private let checkOffImageView = UIImageView(image: UIImage(resource: .checkOff))
    private let checkImageView = UIImageView(image: UIImage(resource: .check).withRenderingMode(.alwaysTemplate))
    private let titleLabel = UILabel(config: .body14Regular)

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(checkBoxView)
        addSubview(titleLabel)
        checkBoxView.addSubview(checkOffImageView)
        checkBoxView.addSubview(checkImageView)

        checkOffImageView.contentMode = .scaleAspectFit
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.tintColor = .primary400
        checkBoxView.isUserInteractionEnabled = false
        titleLabel.numberOfLines = 1

        checkBoxView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        checkOffImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        checkImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(checkBoxView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        snp.makeConstraints {
            $0.height.equalTo(44)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, isSelected: Bool, keyword: String) {
        checkImageView.isHidden = false
        checkImageView.tintColor = isSelected ? .primary400 : .gray400
        titleLabel.attributedText = Self.highlightedText(
            title,
            keyword: keyword,
            baseColor: isSelected ? .gray900 : .gray500
        )
    }

    private static func highlightedText(
        _ text: String,
        keyword: String,
        baseColor: UIColor
    ) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: LabelConfiguration.body14Regular.font,
                .foregroundColor: baseColor
            ]
        )
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedKeyword.isEmpty == false else {
            return attributedText
        }

        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(
            of: trimmedKeyword,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: searchRange
        ) {
            attributedText.addAttributes(
                [
                    .font: LabelConfiguration.body14Regular.font,
                    .foregroundColor: UIColor.primary400
                ],
                range: NSRange(range, in: text)
            )
            searchRange = range.upperBound..<text.endIndex
        }
        return attributedText
    }
}

final class MapFilterViewController: UIViewController {
    var applyButtonTapped: ((FacilityFilter) -> Void)?
    var singleCategorySelected: ((FacilityCategory) -> Void)?

    private var draftFilter: FacilityFilter // 임시 필터 값
    private let priceSamples: [Int]
    private let mode: MapFilterMode
    private let categorySelectionBehavior: MapFilterCategorySelectionBehavior
    private let filterView = MapFilterView()
    private var sectionStackView: UIStackView { filterView.sectionStackView }
    private var closeButton: UIButton { filterView.closeButton }
    private var resetButton: DesignButton { filterView.resetButton }
    private var applyButton: DesignButton { filterView.applyButton }
    private var bottomActionView: UIView { filterView.bottomActionView }
    private var minimumPriceTextField: UITextField { filterView.minimumPriceTextField }
    private var maximumPriceTextField: UITextField { filterView.maximumPriceTextField }
    private var categorySearchTextField: SearchBar { filterView.categorySearchTextField }
    private let disposeBag = DisposeBag()
    private let priceRangeSlider = PriceRangeSliderView()

    private var categoryButtons: [FacilityCategory: FilterOptionChipButton] = [:]
    private var dayButtons: [Weekday: FilterOptionChipButton] = [:]
    private var timeButtons: [TimeSlot: FilterOptionChipButton] = [:]
    private var categoryOptionButtons: [(category: FacilityCategory, button: FilterOptionChipButton)] = []
    private var categoryGroupControls: [CategoryGroupControl] = []
    private var categorySelectionRows: [(option: CategorySelectionOption, row: CategoryOptionRow)] = []
    private var selectedCategorySummaryStackView: UIStackView?
    private var selectedCategoryGroupIndex = 0
    private var categorySearchKeyword = ""
    private var keyboardObserverTokens: [NSObjectProtocol] = []

    private let categoryTitleLabel = UILabel(text: "운동 종목", config: .body14Regular, color: .gray900)
    private let categoryHeaderSeparatorView = UIView().then {
        $0.backgroundColor = .gray100
    }
    private let categoryPickerContainerView = UIView()
    private let categoryGroupScrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = true
    }
    private let categoryGroupStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 4
    }
    private let categoryDividerView = UIView().then {
        $0.backgroundColor = .gray200
    }
    private let categoryOptionScrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = true
    }
    private let categoryOptionStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
    }
    private let categorySearchResultScrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = true
        $0.isHidden = true
    }
    private let categorySearchResultStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
    }
    private let categorySelectedContainerView = UIView()
    private let categorySelectedSeparatorView = UIView().then {
        $0.backgroundColor = .gray100
    }
    private let categorySelectedTitleLabel = UILabel(
        text: "선택된 운동 종목",
        config: .body13Regular,
        color: .gray900
    )

    init(
        filter: FacilityFilter,
        priceSamples: [Int] = [],
        mode: MapFilterMode = .all,
        categorySelectionBehavior: MapFilterCategorySelectionBehavior = .multiple
    ) {
        self.draftFilter = filter
        self.priceSamples = priceSamples
        self.mode = mode
        self.categorySelectionBehavior = categorySelectionBehavior
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet

        if let sheetPresentationController {
            let detentIdentifier = mode.detentIdentifier
            sheetPresentationController.detents = [
                .custom(identifier: detentIdentifier) { context in
                    min(mode.detentHeight, context.maximumDetentValue)
                }
            ]
            sheetPresentationController.largestUndimmedDetentIdentifier = detentIdentifier
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.preferredCornerRadius = 16
        }
    }

    deinit {
        keyboardObserverTokens.forEach(NotificationCenter.default.removeObserver)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = filterView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureSections()
        configureActions()
        configureKeyboardHandlingIfNeeded()
        if mode.usesPriceFilter {
            configurePriceRangeSlider()
            updatePriceTextFields()
        }
        updateSelectionStates()
    }

    private func configureSections() {
        switch mode {
        case .all:
            addDaySection(topInset: 0)
            addTimeSection()
            sectionStackView.addArrangedSubview(makeSelectedCategorySection(showsSeparator: true))
            sectionStackView.addArrangedSubview(makePriceSection(topInset: 20, showsSeparator: false))

        case .category:
            configureCategorySelectionLayout()

        case .schedule:
            addDaySection(topInset: 0)
            addTimeSection(showsSeparator: false)

        case .price:
            sectionStackView.addArrangedSubview(makePriceSection(topInset: 0, showsSeparator: false))
        }
    }

    private func configureActions() {
        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(didTapResetButton), for: .touchUpInside)
        applyButton.addTarget(self, action: #selector(didTapApplyButton), for: .touchUpInside)
        minimumPriceTextField.addTarget(self, action: #selector(didChangePriceTextField), for: .editingChanged)
        maximumPriceTextField.addTarget(self, action: #selector(didChangePriceTextField), for: .editingChanged)
        priceRangeSlider.addTarget(self, action: #selector(didChangePriceRangeSlider), for: .valueChanged)
        categorySearchTextField.rx.text.orEmpty
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] keyword in
                self?.updateCategorySearchResults(keyword: keyword)
            })
            .disposed(by: disposeBag)
    }

    private func configureCategorySelectionLayout() {
        filterView.scrollView.isHidden = true

        filterView.addSubview(categoryTitleLabel)
        filterView.addSubview(categorySearchTextField)
        filterView.addSubview(categoryHeaderSeparatorView)
        filterView.addSubview(categoryPickerContainerView)
        filterView.addSubview(categorySelectedContainerView)

        categoryPickerContainerView.addSubview(categoryGroupScrollView)
        categoryPickerContainerView.addSubview(categoryDividerView)
        categoryPickerContainerView.addSubview(categoryOptionScrollView)
        categoryPickerContainerView.addSubview(categorySearchResultScrollView)
        categoryGroupScrollView.addSubview(categoryGroupStackView)
        categoryOptionScrollView.addSubview(categoryOptionStackView)
        categorySearchResultScrollView.addSubview(categorySearchResultStackView)

        let (selectedScrollView, selectedStackView) = makeSelectedCategorySummaryScrollView()
        selectedCategorySummaryStackView = selectedStackView
        categorySelectedContainerView.addSubview(categorySelectedSeparatorView)
        categorySelectedContainerView.addSubview(categorySelectedTitleLabel)
        categorySelectedContainerView.addSubview(selectedScrollView)

        categoryTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalTo(closeButton)
        }

        categorySearchTextField.snp.makeConstraints {
            $0.top.equalTo(categoryTitleLabel.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }

        categoryHeaderSeparatorView.snp.makeConstraints {
            $0.top.equalTo(categorySearchTextField.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }

        categorySelectedContainerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomActionView.snp.top)
            $0.height.equalTo(96)
        }

        categorySelectedSeparatorView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(1)
        }

        categorySelectedTitleLabel.snp.makeConstraints {
            $0.top.equalTo(categorySelectedSeparatorView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        selectedScrollView.snp.makeConstraints {
            $0.top.equalTo(categorySelectedTitleLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.greaterThanOrEqualTo(30)
        }

        categoryPickerContainerView.snp.makeConstraints {
            $0.top.equalTo(categoryHeaderSeparatorView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(categorySelectedContainerView.snp.top)
        }

        categoryGroupScrollView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(16)
            $0.leading.equalToSuperview().inset(16)
            $0.width.equalTo(168)
        }

        categoryGroupStackView.snp.makeConstraints {
            $0.edges.equalTo(categoryGroupScrollView.contentLayoutGuide)
            $0.width.equalTo(categoryGroupScrollView.frameLayoutGuide)
        }

        categoryDividerView.snp.makeConstraints {
            $0.leading.equalTo(categoryGroupScrollView.snp.trailing)
            $0.top.bottom.equalToSuperview().inset(16)
            $0.width.equalTo(1)
        }

        categoryOptionScrollView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(8)
            $0.leading.equalTo(categoryDividerView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(16)
        }

        categoryOptionStackView.snp.makeConstraints {
            $0.edges.equalTo(categoryOptionScrollView.contentLayoutGuide)
            $0.width.equalTo(categoryOptionScrollView.frameLayoutGuide)
        }

        categorySearchResultScrollView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }

        categorySearchResultStackView.snp.makeConstraints {
            $0.edges.equalTo(categorySearchResultScrollView.contentLayoutGuide)
            $0.width.equalTo(categorySearchResultScrollView.frameLayoutGuide)
        }

        reloadCategoryPicker()
    }

    private func configureKeyboardHandlingIfNeeded() {
        guard mode == .category else { return }

        let notificationCenter = NotificationCenter.default
        keyboardObserverTokens = [
            notificationCenter.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleKeyboardWillShow(notification)
            },
            notificationCenter.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleKeyboardWillHide(notification)
            }
        ]
    }

    private func handleKeyboardWillShow(_ notification: Notification) {
        guard mode == .category,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let keyboardOverlap = max(0, view.bounds.maxY - keyboardFrameInView.minY)
        bottomActionView.isHidden = true
        remakeCategorySelectedContainerConstraints(bottomInset: keyboardOverlap)
        animateKeyboardLayout(with: notification)
    }

    private func handleKeyboardWillHide(_ notification: Notification) {
        guard mode == .category else { return }

        bottomActionView.isHidden = false
        remakeCategorySelectedContainerConstraints(bottomInset: nil)
        animateKeyboardLayout(with: notification)
    }

    private func remakeCategorySelectedContainerConstraints(bottomInset: CGFloat?) {
        categorySelectedContainerView.snp.remakeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(96)
            if let bottomInset {
                $0.bottom.equalToSuperview().inset(bottomInset)
            } else {
                $0.bottom.equalTo(bottomActionView.snp.top)
            }
        }
    }

    private func animateKeyboardLayout(with notification: Notification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }

    private func reloadCategoryPicker() {
        let keyword = categorySearchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        categorySelectionRows.removeAll()
        removeArrangedSubviews(from: categoryGroupStackView)
        removeArrangedSubviews(from: categoryOptionStackView)
        removeArrangedSubviews(from: categorySearchResultStackView)

        let isSearching = keyword.isEmpty == false
        categoryGroupScrollView.isHidden = isSearching
        categoryDividerView.isHidden = isSearching
        categoryOptionScrollView.isHidden = isSearching
        categorySearchResultScrollView.isHidden = isSearching == false

        if isSearching {
            renderCategoryOptions(
                categorySearchOptions(matching: keyword),
                in: categorySearchResultStackView,
                keyword: keyword
            )
            return
        }

        let groups = makeCategoryGroups()
        if selectedCategoryGroupIndex >= groups.count {
            selectedCategoryGroupIndex = 0
        }

        categoryGroupControls = groups.enumerated().map { index, group in
            let control = CategoryGroupControl()
            let selectedCount = group.categories.filter { draftFilter.categories.contains($0) }.count
            control.configure(
                title: group.title,
                count: selectedCount,
                isSelected: index == selectedCategoryGroupIndex
            )
            control.addAction(UIAction { [weak self] _ in
                self?.selectedCategoryGroupIndex = index
                self?.reloadCategoryPicker()
            }, for: .touchUpInside)
            categoryGroupStackView.addArrangedSubview(control)
            control.snp.makeConstraints {
                $0.height.equalTo(44)
            }
            return control
        }

        guard groups.indices.contains(selectedCategoryGroupIndex) else { return }
        renderCategoryOptions(
            categoryOptions(for: groups[selectedCategoryGroupIndex]),
            in: categoryOptionStackView,
            keyword: ""
        )
    }

    private func renderCategoryOptions(
        _ options: [CategorySelectionOption],
        in stackView: UIStackView,
        keyword: String
    ) {
        options.forEach { option in
            let row = CategoryOptionRow()
            row.configure(
                title: option.title,
                isSelected: isCategoryOptionSelected(option),
                keyword: keyword
            )
            row.addAction(UIAction { [weak self] _ in
                self?.toggleCategoryOption(option)
            }, for: .touchUpInside)
            stackView.addArrangedSubview(row)
            categorySelectionRows.append((option, row))
        }
    }

    private func categoryOptions(for group: CategoryGroup) -> [CategorySelectionOption] {
        let categories = Set(group.categories)
        guard categories.isEmpty == false else {
            return []
        }
        
        if categorySelectionBehavior == .single {
            return group.categories.map {
                CategorySelectionOption(title: $0.title, categories: [$0])
            }
        }

        return [
            CategorySelectionOption(
                title: "\(group.title) 전체",
                categories: categories
            )
        ] + group.categories.map {
            CategorySelectionOption(title: $0.title, categories: [$0])
        }
    }

    private func categorySearchOptions(matching keyword: String) -> [CategorySelectionOption] {
        var seenTitles = Set<String>()
        return makeCategoryGroups()
            .flatMap(categoryOptions(for:))
            .filter { option in
                option.title.range(
                    of: keyword,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) != nil
            }
            .filter { option in
                seenTitles.insert(option.title).inserted
            }
    }

    private func isCategoryOptionSelected(_ option: CategorySelectionOption) -> Bool {
        option.categories.isEmpty == false && option.categories.isSubset(of: draftFilter.categories)
    }

    private func toggleCategoryOption(_ option: CategorySelectionOption) {
        guard option.categories.isEmpty == false else { return }
        
        if categorySelectionBehavior == .single,
           let category = option.categories.first {
            draftFilter.categories = [category]
            updateSelectionStates()
            return
        }

        if isCategoryOptionSelected(option) {
            draftFilter.categories.subtract(option.categories)
        } else {
            draftFilter.categories.formUnion(option.categories)
        }
        updateSelectionStates()
    }

    private func removeArrangedSubviews(from stackView: UIStackView) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func addDaySection(topInset: CGFloat = 20, showsSeparator: Bool = true) {
        sectionStackView.addArrangedSubview(
            makeSection(
                title: "요일",
                options: Weekday.allCases,
                titleForOption: { $0.title },
                numberOfItemsPerRow: 8,
                buttons: &dayButtons,
                selectionHandler: { [weak self] day in
                    self?.toggleDay(day)
                },
                topInset: topInset,
                showsSeparator: showsSeparator
            )
        )
    }

    private func addTimeSection(topInset: CGFloat = 20, showsSeparator: Bool = true) {
        sectionStackView.addArrangedSubview(
            makeSection(
                title: "시간대",
                options: TimeSlot.allCases,
                titleForOption: { $0.filterTitle },
                numberOfItemsPerRow: 3,
                buttons: &timeButtons,
                selectionHandler: { [weak self] timeSlot in
                    self?.toggleTimeSlot(timeSlot)
                },
                topInset: topInset,
                showsSeparator: showsSeparator
            )
        )
    }

    private func makeSection<Option: Hashable>(
        title: String,
        options: [Option],
        titleForOption: (Option) -> String,
        numberOfItemsPerRow: Int,
        buttons: inout [Option: FilterOptionChipButton],
        selectionHandler: @escaping (Option) -> Void,
        topInset: CGFloat = 20,
        showsSeparator: Bool = true
    ) -> UIView {
        let containerView = UIView()
        let titleLabel = makeSectionTitleLabel(text: title)
        let rowsStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 8
        }

        containerView.addSubview(titleLabel)
        containerView.addSubview(rowsStackView)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(topInset)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        rowsStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(16)
        }

        for rowOptions in options.chunked(into: numberOfItemsPerRow) {
            let rowStackView = UIStackView().then {
                $0.axis = .horizontal
                $0.spacing = 8
            }

            rowOptions.forEach { option in
                let button = makeChipButton(title: titleForOption(option))
                button.addAction(UIAction { _ in
                    selectionHandler(option)
                }, for: .touchUpInside)
                buttons[option] = button
                rowStackView.addArrangedSubview(button)
            }

            rowStackView.addArrangedSubview(UIView())
            rowsStackView.addArrangedSubview(rowStackView)
        }

        if showsSeparator {
            addSeparator(to: containerView)
        }
        return containerView
    }

    private func makeSelectedCategorySection(showsSeparator: Bool) -> UIView {
        let containerView = UIView()
        let titleLabel = makeSectionTitleLabel(text: "운동 종목")
        let (selectedScrollView, selectedStackView) = makeSelectedCategorySummaryScrollView()
        let selectButton = UIButton(type: .system).then {
            $0.setTitle("선택하기", for: .normal)
            $0.titleLabel?.font = LabelConfiguration.body14Semibold.font
            $0.setTitleColor(.gray400, for: .normal)
            $0.backgroundColor = .systemBackground
            $0.layer.cornerRadius = 18
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.gray100.cgColor
        }

        selectedCategorySummaryStackView = selectedStackView
        containerView.addSubview(titleLabel)
        containerView.addSubview(selectedScrollView)
        containerView.addSubview(selectButton)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        selectedScrollView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.greaterThanOrEqualTo(30)
        }

        selectButton.snp.makeConstraints {
            $0.top.equalTo(selectedScrollView.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
            $0.bottom.equalToSuperview().inset(20)
        }

        selectButton.addAction(UIAction { [weak self] _ in
            self?.presentCategorySelectionModal()
        }, for: .touchUpInside)

        if showsSeparator {
            addSeparator(to: containerView)
        }
        return containerView
    }

    private func makeCategorySection(topInset: CGFloat, showsSearch: Bool, showsSeparator: Bool) -> UIView {
        let containerView = UIView()
        let titleLabel = makeSectionTitleLabel(text: "운동 종목")
        let selectorContainerView = UIView()
        let groupStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 4
        }
        let optionStackView = UIStackView().then {
            $0.axis = .vertical
            $0.spacing = 8
        }
        let dividerView = UIView().then {
            $0.backgroundColor = .gray200
        }

        containerView.addSubview(titleLabel)
        containerView.addSubview(selectorContainerView)
        selectorContainerView.addSubview(groupStackView)
        selectorContainerView.addSubview(dividerView)
        selectorContainerView.addSubview(optionStackView)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(topInset)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        if showsSearch {
            containerView.addSubview(categorySearchTextField)
            categorySearchTextField.snp.makeConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(10)
                $0.leading.trailing.equalToSuperview().inset(16)
                $0.height.equalTo(36)
            }

            selectorContainerView.snp.makeConstraints {
                $0.top.equalTo(categorySearchTextField.snp.bottom).offset(14)
                $0.leading.trailing.equalToSuperview().inset(16)
            }
        } else {
            selectorContainerView.snp.makeConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(8)
                $0.leading.trailing.equalToSuperview().inset(16)
            }
        }

        groupStackView.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview()
            $0.width.equalTo(132)
        }

        dividerView.snp.makeConstraints {
            $0.leading.equalTo(groupStackView.snp.trailing).offset(8)
            $0.top.bottom.equalToSuperview()
            $0.width.equalTo(1)
        }

        optionStackView.snp.makeConstraints {
            $0.top.trailing.bottom.equalToSuperview()
            $0.leading.equalTo(dividerView.snp.trailing).offset(16)
        }

        let categoryGroups = makeCategoryGroups()
        categoryGroups.forEach { group in
            groupStackView.addArrangedSubview(makeCategoryGroupLabel(group))
        }

        categoryGroups.flatMap(\.categories).forEach { category in
            let button = makeChipButton(title: category.title)
            button.addAction(UIAction { [weak self] _ in
                self?.toggleCategory(category)
            }, for: .touchUpInside)
            categoryButtons[category] = button
            categoryOptionButtons.append((category, button))
            optionStackView.addArrangedSubview(button)
        }

        let selectedTitleLabel = makeSectionTitleLabel(text: "선택된 운동 종목")
        let (selectedScrollView, selectedStackView) = makeSelectedCategorySummaryScrollView()
        selectedCategorySummaryStackView = selectedStackView
        containerView.addSubview(selectedTitleLabel)
        containerView.addSubview(selectedScrollView)

        selectorContainerView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(210)
        }

        selectedTitleLabel.snp.makeConstraints {
            $0.top.equalTo(selectorContainerView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        selectedScrollView.snp.makeConstraints {
            $0.top.equalTo(selectedTitleLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.greaterThanOrEqualTo(30)
            $0.bottom.equalToSuperview().inset(20)
        }

        if showsSeparator {
            addSeparator(to: containerView)
        }
        return containerView
    }

    private func makePriceSection(topInset: CGFloat = 20, showsSeparator: Bool = true) -> UIView {
        let containerView = UIView()
        let titleLabel = makeSectionTitleLabel(text: "가격대")
        let rangeLabel = UILabel(text: "~", config: .title16, color: .gray900).then {
            $0.textAlignment = .center
        }

        containerView.addSubview(titleLabel)
        containerView.addSubview(priceRangeSlider)
        containerView.addSubview(minimumPriceTextField)
        containerView.addSubview(rangeLabel)
        containerView.addSubview(maximumPriceTextField)

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(topInset)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        priceRangeSlider.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
        }

        minimumPriceTextField.snp.makeConstraints {
            $0.top.equalTo(priceRangeSlider.snp.bottom).offset(12)
            $0.leading.equalToSuperview().inset(16)
            $0.height.equalTo(42)
        }

        rangeLabel.snp.makeConstraints {
            $0.leading.equalTo(minimumPriceTextField.snp.trailing).offset(16)
            $0.centerY.equalTo(minimumPriceTextField)
            $0.size.equalTo(12)
        }

        maximumPriceTextField.snp.makeConstraints {
            $0.leading.equalTo(rangeLabel.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.width.height.equalTo(minimumPriceTextField)
            $0.bottom.equalToSuperview().inset(12)
        }

        if showsSeparator {
            addSeparator(to: containerView)
        }
        return containerView
    }

    private func makeCategoryGroups() -> [CategoryGroup] {
        [
            CategoryGroup(title: "헬스", categories: [.gym, .healthPT, .bodybuilding]),
            CategoryGroup(title: "피트니스", categories: [.gx, .trx, .circuitTraining, .spinningBike, .aerobics, .dietRobics, .seniorRobics, .taebo, .jumpingDiet, .jumpingTrampoline, .fitBalance, .womensCircuitExercise]),
            CategoryGroup(title: "요가/필라테스", categories: [.yoga, .powerYoga, .pilates, .snpe]),
            CategoryGroup(title: "체조", categories: [.gymnastics, .kuksundo, .koreanQigong, .taiChi, .lifeGymnastics, .stretching]),
            CategoryGroup(title: "댄스/무용", categories: [.dance, .lineDance, .broadcastDance, .bellyDance, .sportsDance, .zumbaDance, .dietDance, .ballet, .traditionalDance, .koreanDance]),
            CategoryGroup(title: "수중", categories: [.swimming, .survivalSwimming, .aquaticHealthGymnastics, .aquaRobics, .aquaWalking, .aquathlon, .artisticSwimming, .scubaDiving]),
            CategoryGroup(title: "구기", categories: [.basketball, .soccer, .futsal, .baseball, .badminton, .tableTennis, .tennis, .squash, .racquetball, .pickleball, .golf, .parkGolf, .gateball, .billiards, .bowling, .floorball]),
            CategoryGroup(title: "빙상", categories: [.skating, .speedSkating, .figureSkating, .skiing]),
            CategoryGroup(title: "무도/격투", categories: [.kendo, .boxing, .judo, .taekwondo, .taekkyeon, .fencing, .traditionalArchery]),
            CategoryGroup(title: "러닝/사이클/육상", categories: [.running, .jogging, .athletics, .cycling, .runBike, .triathlon]),
            CategoryGroup(title: "생활체육", categories: [.lifeSports, .childSports, .infantSports, .jumpRope, .womensHealthClass, .bodySkillRelease]),
            CategoryGroup(title: "특수체육", categories: [.boccia]),
            CategoryGroup(title: "기타", categories: [.sBoard, .rollerSkating, .hiking, .climbing])
        ]
    }

    private func makeCategoryGroupLabel(_ group: CategoryGroup) -> UILabel {
        let count = group.categories.filter { draftFilter.categories.contains($0) }.count
        let suffix = count > 0 ? " \(count)" : ""
        return UILabel(text: "\(group.title)\(suffix)", config: .body13Regular, color: count > 0 ? .gray900 : .gray500).then {
            $0.backgroundColor = count > 0 ? .gray50 : .clear
            $0.layer.cornerRadius = 8
            $0.layer.masksToBounds = true
            $0.textAlignment = .left
        }
    }

    private func presentCategorySelectionModal() {
        let viewController = MapFilterViewController(
            filter: draftFilter,
            priceSamples: priceSamples,
            mode: .category
        )
        viewController.applyButtonTapped = { [weak self] filter in
            self?.draftFilter.categories = filter.categories
            self?.updateSelectionStates()
        }
        present(viewController, animated: true)
    }

    private func makeSectionTitleLabel(text: String) -> UILabel {
        UILabel(text: text, config: .body14Regular, color: .gray900)
    }

    private func makeChipButton(title: String) -> FilterOptionChipButton {
        FilterOptionChipButton().then {
            $0.setTitle(title, for: .normal)
            $0.setSelectedStyle(false)
        }
    }

    private func makeSelectedCategorySummaryScrollView() -> (UIScrollView, UIStackView) {
        let scrollView = UIScrollView().then {
            $0.showsHorizontalScrollIndicator = false
            $0.showsVerticalScrollIndicator = false
            $0.alwaysBounceHorizontal = true
        }
        let stackView = UIStackView().then {
            $0.axis = .horizontal
            $0.spacing = 8
            $0.alignment = .center
        }

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.height.equalTo(scrollView.frameLayoutGuide)
        }

        return (scrollView, stackView)
    }

    private func addSeparator(to view: UIView) {
        let separatorView = UIView().then {
            $0.backgroundColor = .gray100
        }
        view.addSubview(separatorView)
        separatorView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }

    private func toggleDay(_ day: Weekday?) {
        guard let day else {
            draftFilter.days.removeAll()
            updateSelectionStates()
            return
        }

        draftFilter.days.toggle(day)
        if draftFilter.days.count == Weekday.allCases.count {
            draftFilter.days.removeAll()
        }
        updateSelectionStates()
    }

    private func toggleCategory(_ category: FacilityCategory?) {
        guard let category else {
            draftFilter.categories.removeAll()
            updateSelectionStates()
            return
        }
        
        if categorySelectionBehavior == .single {
            draftFilter.categories = [category]
            updateSelectionStates()
            return
        }

        draftFilter.categories.toggle(category)
        if draftFilter.categories.count == FacilityCategory.allCases.count {
            draftFilter.categories.removeAll()
        }
        updateSelectionStates()
    }

    private func toggleTimeSlot(_ timeSlot: TimeSlot?) {
        guard let timeSlot else {
            draftFilter.timeSlots.removeAll()
            updateSelectionStates()
            return
        }

        draftFilter.timeSlots.toggle(timeSlot)
        if draftFilter.timeSlots.count == TimeSlot.allCases.count {
            draftFilter.timeSlots.removeAll()
        }
        updateSelectionStates()
    }

    private func updateSelectionStates() {
        categoryButtons.forEach { category, button in
            updateChip(button, isSelected: draftFilter.categories.contains(category))
        }

        dayButtons.forEach { day, button in
            updateChip(button, isSelected: draftFilter.days.contains(day))
        }

        timeButtons.forEach { timeSlot, button in
            updateChip(button, isSelected: draftFilter.timeSlots.contains(timeSlot))
        }
        if mode == .category {
            reloadCategoryPicker()
        }
        updateSelectedCategorySummary()
    }

    private func updateSelectedCategorySummary() {
        guard let selectedCategorySummaryStackView else { return }
        removeArrangedSubviews(from: selectedCategorySummaryStackView)

        let selectedItems = selectedCategorySummaryItems()
        if selectedItems.isEmpty {
            let emptyLabel = UILabel(text: "선택된 종목이 없습니다", config: .body13Regular, color: .gray500)
            selectedCategorySummaryStackView.addArrangedSubview(emptyLabel)
        } else {
            selectedItems.forEach { item in
                let chipButton = makeChipButton(title: "\(item.title) ×")
                chipButton.setSelectedStyle(false)
                chipButton.backgroundColor = .gray50
                chipButton.layer.borderColor = UIColor.clear.cgColor
                chipButton.addAction(UIAction { [weak self] _ in
                    self?.draftFilter.categories.subtract(item.categories)
                    self?.updateSelectionStates()
                }, for: .touchUpInside)
                selectedCategorySummaryStackView.addArrangedSubview(chipButton)
            }
        }
    }

    private func selectedCategorySummaryItems() -> [(title: String, categories: Set<FacilityCategory>)] {
        var remainingCategories = draftFilter.categories
        var items: [(title: String, categories: Set<FacilityCategory>)] = []
        
        if categorySelectionBehavior == .single {
            return FacilityCategory.allCases
                .filter { draftFilter.categories.contains($0) }
                .map { ($0.title, [$0]) }
        }

        makeCategoryGroups().forEach { group in
            let groupCategories = Set(group.categories)
            guard groupCategories.isEmpty == false,
                  groupCategories.isSubset(of: remainingCategories) else {
                return
            }

            items.append(("\(group.title) 전체", groupCategories))
            remainingCategories.subtract(groupCategories)
        }

        FacilityCategory.allCases
            .filter { remainingCategories.contains($0) }
            .forEach { category in
                items.append((category.title, [category]))
            }

        return items
    }

    private func updateChip(_ button: FilterOptionChipButton, isSelected: Bool) {
        button.setSelectedStyle(isSelected)
    }

    private func configurePriceRangeSlider() {
        priceRangeSlider.configure(
            priceSamples: priceSamples,
            selectedMinimumPrice: draftFilter.minimumPrice,
            selectedMaximumPrice: draftFilter.maximumPrice
        )
        updateDraftPriceFilterFromSlider()
    }

    private func updatePriceTextFields() {
        minimumPriceTextField.text = formatPrice(priceRangeSlider.selectedMinimumPrice)
        maximumPriceTextField.text = formatPrice(priceRangeSlider.selectedMaximumPrice)
    }

    private func formatPrice(_ price: Int) -> String {
        "\(price.formatted()) 원"
    }

    private func parsePrice(_ text: String?) -> Int? {
        guard let text else { return nil }
        let digits = text.filter(\.isNumber)
        return Int(digits)
    }

    @objc private func didChangePriceTextField() {
        priceRangeSlider.setSelectedRange(
            minimumPrice: parsePrice(minimumPriceTextField.text),
            maximumPrice: parsePrice(maximumPriceTextField.text),
            sendsValueChanged: false
        )
        updateDraftPriceFilterFromSlider()
    }

    @objc private func didChangePriceRangeSlider() {
        updateDraftPriceFilterFromSlider()
        updatePriceTextFields()
    }

    private func updateDraftPriceFilterFromSlider() {
        draftFilter.minimumPrice = priceRangeSlider.selectedMinimumPrice > priceRangeSlider.minimumPrice
            ? priceRangeSlider.selectedMinimumPrice
            : nil
        draftFilter.maximumPrice = priceRangeSlider.selectedMaximumPrice < priceRangeSlider.maximumPrice
            ? priceRangeSlider.selectedMaximumPrice
            : nil
    }

    private func updateCategorySearchResults(keyword: String) {
        categorySearchKeyword = keyword
        if mode == .category {
            reloadCategoryPicker()
        }
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true)
    }

    @objc private func didTapResetButton() {
        switch mode {
        case .all:
            draftFilter.categories.removeAll()
            draftFilter.days.removeAll()
            draftFilter.timeSlots.removeAll()
            draftFilter.minimumPrice = nil
            draftFilter.maximumPrice = nil

        case .category:
            draftFilter.categories.removeAll()

        case .schedule:
            draftFilter.days.removeAll()
            draftFilter.timeSlots.removeAll()

        case .price:
            draftFilter.minimumPrice = nil
            draftFilter.maximumPrice = nil
        }
        if mode.usesPriceFilter {
            priceRangeSlider.setSelectedRange(
                minimumPrice: draftFilter.minimumPrice,
                maximumPrice: draftFilter.maximumPrice,
                sendsValueChanged: false
            )
            updateDraftPriceFilterFromSlider()
            updatePriceTextFields()
        }
        updateSelectionStates()
    }

    @objc private func didTapApplyButton() {
        if mode.usesPriceFilter {
            didChangePriceTextField()
        }
        
        if categorySelectionBehavior == .single,
           let category = draftFilter.categories.first {
            singleCategorySelected?(category)
            dismiss(animated: true)
            return
        }
        
        applyButtonTapped?(draftFilter)
        dismiss(animated: true)
    }
}

private extension MapFilterMode {
    var detentIdentifier: UISheetPresentationController.Detent.Identifier {
        switch self {
        case .all:
            return .init("mapFilterAll")
        case .category:
            return .init("mapFilterCategory")
        case .schedule:
            return .init("mapFilterSchedule")
        case .price:
            return .init("mapFilterPrice")
        }
    }

    var detentHeight: CGFloat {
        switch self {
        case .all: return 650
        case .category: return 680
        case .schedule: return 350
        case .price: return 310
        }
    }

    var usesPriceFilter: Bool {
        switch self {
        case .all, .price:
            return true
        case .category, .schedule:
            return false
        }
    }
}

private extension Set {
    mutating func toggle(_ member: Element) {
        if contains(member) {
            remove(member)
        } else {
            insert(member)
        }
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

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

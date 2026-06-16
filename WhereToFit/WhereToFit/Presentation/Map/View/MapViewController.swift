//
//  MapViewController.swift
//  WhereToFit
//
//  Created by 김주희 on 5/27/26.
//

import UIKit
import CoreLocation
import NMapsMap
import ReactorKit
import RxCocoa
import RxSwift

private enum BottomPanelDetent {
    case collapsed
    case medium
    case expanded
}

private enum MarkerPresentationStyle: Equatable {
    case gym
    case sameCoordinateCount
    case nearbyCount(clusterGridSizeMeters: Int)
}

private enum MapMetric {
    static let collapsedBottomPanelHeight: CGFloat = 180
    static let mediumBottomPanelHeight: CGFloat = 380
    static let expandedPanelTopInset: CGFloat = 88
    static let currentLocationButtonMinimumGap: CGFloat = 10
    static let searchSuggestionMaximumHeight: CGFloat = 256
    static let searchDebounceMilliseconds = 250
    static let detentVelocityThreshold: CGFloat = 500
}

private enum MapAnimationMetric {
    static let bottomPanelDuration: TimeInterval = 0.28
    static let bottomPanelSpringDamping: CGFloat = 0.86
    static let bottomPanelInitialVelocity: CGFloat = 0.45
}

private enum MapZoomLevel {
    static let gymMarkerMinimum: Double = 15
    static let sameCoordinateCountMarkerMinimum: Double = 14
}

private struct FacilityMarkerGroup {
    let coordinate: GeoCoordinate
    var facilities: [FitnessFacility]
}

final class MapViewController: BaseViewController<MapReactor> {
    private let mapView = MapView()
    private let searchMapSuggestionsUseCase: SearchMapSuggestionsUseCase
    private var searchTextField: SearchBar { mapView.searchTextField }
    private var searchSuggestionTableView: UITableView { mapView.searchSuggestionTableView }
    private var naverMapView: NMFNaverMapView { mapView.naverMapView }
    private var missingKeyView: UIView { mapView.missingKeyView }
    private var currentLocationButton: UIButton { mapView.currentLocationButton }
    private var bottomPanelView: UIView { mapView.bottomPanelView }
    private var tableView: UITableView { mapView.tableView }
    private var loadingIndicatorView: UIActivityIndicatorView { mapView.loadingIndicatorView }
    private var emptyStateLabel: UILabel { mapView.emptyStateLabel }
    private var allFilterButton: UIButton { mapView.allFilterButton }
    private var aiButton: UIButton { mapView.aiButton }
    private var categoryButton: UIButton { mapView.categoryButton }
    private var dayButton: UIButton { mapView.dayButton }
    private var timeButton: UIButton { mapView.timeButton }
    private var priceButton: UIButton { mapView.priceButton }

    private var allFacilities: [FitnessFacility] = []
    private var unfilteredFacilities: [FitnessFacility] = []
    private var unfilteredMarkerFacilities: [FitnessFacility] = []
    private var markerFacilities: [FitnessFacility] = []
    private var displayedFacilities: [FitnessFacility] = []
    private var searchSuggestions: [MapSearchSuggestion] = []
    private var latestSearchSuggestionQuery = ""
    private var selectedFacility: FitnessFacility?
    private var markers: [NMFMarker] = []
    private var renderedMarkerPresentationStyle: MarkerPresentationStyle?
    private var shouldUpdateListForVisibleMapBounds = false
    private var bottomPanelDetent: BottomPanelDetent = .collapsed
    private var bottomPanelHeightAtPanStart: CGFloat = MapMetric.collapsedBottomPanelHeight
    private var isShowingFacilityEmptyState = false
    private let locationService = LocationService()
    private var currentUserCoordinate: GeoCoordinate?
    private let defaultCoordinate = GeoCoordinate(latitude: 37.576022, longitude: 126.976900) // 기본 좌표 광화문
    private var errorMessage: String?

    init(
        reactor: MapReactor?,
        searchMapSuggestionsUseCase: SearchMapSuggestionsUseCase
    ) {
        self.searchMapSuggestionsUseCase = searchMapSuggestionsUseCase
        super.init(reactor: reactor)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = mapView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureBottomPanelGesture()
        configureFilterButtonActions()
        configureMap()
        configureTraitChangeHandling()
        tableView.dataSource = self
        tableView.delegate = self
        searchSuggestionTableView.dataSource = self
        searchSuggestionTableView.delegate = self
        moveCamera(to: defaultCoordinate)
        reactor?.action.onNext(.viewDidLoad)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationService.requestCurrentLocation()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.updateBottomPanelHeight(bottomPanelHeight(for: bottomPanelDetent))
    }

    override func bind(reactor: MapReactor) {
        searchTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .skip(1)
            .map(MapReactor.Action.searchTextChanged)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchTextField.rx.search
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .subscribe(onNext: { [weak self] query in
                self?.moveMapForSearchQuery(query)
            })
            .disposed(by: disposeBag)

        searchTextField.rx.text.orEmpty
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .distinctUntilChanged()
            .debounce(.milliseconds(MapMetric.searchDebounceMilliseconds), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] query in
                self?.updateSearchSuggestions(for: query)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.markerFacilities)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] facilities in
                self?.markerFacilities = facilities
                self?.renderMarkers(facilities)
                self?.requestProgramsForVisibleMarkerFacilities()
                self?.updateDisplayedFacilities()
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.allMarkerFacilities)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] facilities in
                guard let self else { return }
                self.unfilteredMarkerFacilities = facilities
                self.requestProgramsForVisibleMarkerFacilities()
                self.updateDisplayedFacilities()
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.allFacilities)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] facilities in
                self?.unfilteredFacilities = facilities
                self?.updateDisplayedFacilities()
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.facilities)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] facilities in
                self?.allFacilities = facilities
                self?.updateDisplayedFacilities()
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading || $0.isProgramLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                isLoading ? self?.loadingIndicatorView.startAnimating() : self?.loadingIndicatorView.stopAnimating()
                self?.updateDisplayedFacilities()
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.errorMessage)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.errorMessage = message
                self?.updateDisplayedFacilities()
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.selectedFacility)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] facility in
                guard let self else { return }
                let didSelectNewFacility = facility != nil && facility?.id != self.selectedFacility?.id
                self.selectedFacility = facility
                self.updateDisplayedFacilities()

                if didSelectNewFacility {
                    self.setBottomPanelDetent(.medium, animated: true)
                }
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.filter)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] filter in
                self?.mapView.updateFilterButtons(filter)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.isNaverMapKeyConfigured)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isConfigured in
                self?.missingKeyView.isHidden = isConfigured
            })
            .disposed(by: disposeBag)

        reactor.state
            .compactMap(\.reservationURLToOpen)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] url in
                UIApplication.shared.open(url)
                self?.reactor?.action.onNext(.didOpenReservationURL)
            })
            .disposed(by: disposeBag)
    }

    private func configureBottomPanelGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleBottomPanelPan(_:)))
        panGesture.delegate = self
        bottomPanelView.addGestureRecognizer(panGesture)
    }

    private func configureFilterButtonActions() {
        allFilterButton.addAction(UIAction { [weak self] _ in
            self?.presentFilterModal(mode: .all)
        }, for: .touchUpInside)

        aiButton.addAction(UIAction { [weak self] _ in
            self?.reactor?.action.onNext(.toggleAIRecommendation)
        }, for: .touchUpInside)

        categoryButton.addAction(UIAction { [weak self] _ in
            self?.presentFilterModal(mode: .category)
        }, for: .touchUpInside)
        dayButton.addAction(UIAction { [weak self] _ in
            self?.presentFilterModal(mode: .schedule)
        }, for: .touchUpInside)
        timeButton.addAction(UIAction { [weak self] _ in
            self?.presentFilterModal(mode: .schedule)
        }, for: .touchUpInside)
        priceButton.addAction(UIAction { [weak self] _ in
            self?.presentFilterModal(mode: .price)
        }, for: .touchUpInside)
    }

    private func configureMap() {
        naverMapView.showZoomControls = false
        naverMapView.showLocationButton = false
        naverMapView.mapView.addCameraDelegate(delegate: self)
        naverMapView.mapView.touchDelegate = self
        applyMapAppearance()
        locationService.locationUpdated = { [weak self] coordinate in
            DispatchQueue.main.async {
                self?.updateCurrentLocation(
                    GeoCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                )
            }
        }
        locationService.locationUnavailable = { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                self.moveCamera(to: self.defaultCoordinate)
            }
        }
        currentLocationButton.addTarget(self, action: #selector(didTapCurrentLocationButton), for: .touchUpInside)
    }

    private func configureTraitChangeHandling() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: Self, _) in
            viewController.applyMapAppearance()
            viewController.renderMarkers(viewController.markerFacilities)
        }
    }

    private func applyMapAppearance() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        naverMapView.mapView.isNightModeEnabled = isDarkMode
        naverMapView.backgroundColor = .systemBackground
        naverMapView.mapView.backgroundColor = .systemBackground
    }

    private func presentFilterModal(mode: MapFilterMode) {
        guard let filter = reactor?.currentState.filter else { return }
        let priceSamples = (reactor?.currentState.allFacilities ?? allFacilities).map(\.price)
        steps.accept(AppStep.mapFilter(filter, priceSamples: priceSamples, mode: mode))
    }

    private func updateSearchSuggestions(for query: String) {
        latestSearchSuggestionQuery = query

        guard query.isEmpty == false else {
            showSearchSuggestions([])
            return
        }

        // 입력 즉시 로컬 시설 결과를 먼저 보여주고, 네이버 결과는 도착하면 뒤에 합쳐 UX 지연을 줄입니다.
        let localSuggestions = makeLocalSearchSuggestions(for: query)
        showSearchSuggestions(localSuggestions)

        guard query.count >= 2 else { return }

        Task { [weak self] in
            guard let self else { return }
            let remoteSuggestions = await fetchRemoteSearchSuggestions(for: query)

            await MainActor.run {
                // 사용자가 그 사이에 다른 검색어를 입력했다면 오래된 네이버 응답은 버립니다.
                guard self.latestSearchSuggestionQuery == query else { return }
                let currentLocalSuggestions = self.makeLocalSearchSuggestions(for: query)
                self.showSearchSuggestions(
                    self.mergeSearchSuggestions(
                        currentLocalSuggestions,
                        remoteSuggestions
                    )
                )
            }
        }
    }

    private func fetchRemoteSearchSuggestions(for query: String) async -> [MapSearchSuggestion] {
        await searchMapSuggestionsUseCase.fetchRemoteSuggestions(
            query: query,
            referenceCoordinate: searchDistanceReferenceCoordinate
        )
    }

    private func makeLocalSearchSuggestions(for query: String) -> [MapSearchSuggestion] {
        searchMapSuggestionsUseCase.makeLocalSuggestions(
            query: query,
            facilities: reactor?.currentState.markerFacilities ?? markerFacilities,
            referenceCoordinate: searchDistanceReferenceCoordinate
        )
    }

    private func mergeSearchSuggestions(
        _ localSuggestions: [MapSearchSuggestion],
        _ remoteSuggestions: [MapSearchSuggestion]
    ) -> [MapSearchSuggestion] {
        searchMapSuggestionsUseCase.mergeSuggestions(localSuggestions, remoteSuggestions)
    }

    private func showSearchSuggestions(_ suggestions: [MapSearchSuggestion]) {
        searchSuggestions = suggestions
        searchSuggestionTableView.reloadData()
        searchSuggestionTableView.isHidden = suggestions.isEmpty
        mapView.updateSearchSuggestionHeight(
            min(CGFloat(suggestions.count) * SearchSuggestionCell.rowHeight, MapMetric.searchSuggestionMaximumHeight)
        )
    }

    private func selectSearchSuggestion(_ suggestion: MapSearchSuggestion) {
        searchTextField.text = suggestion.title
        showSearchSuggestions([])
        view.endEditing(true)
        reactor?.action.onNext(.selectFacility(suggestion.facilityID))
        shouldUpdateListForVisibleMapBounds = true
        errorMessage = nil
        moveCamera(to: suggestion.coordinate, zoom: suggestion.preferredZoom)
        setBottomPanelDetent(.medium, animated: true)
    }

    private func moveMapForSearchQuery(_ query: String) {
        view.endEditing(true)

        // 추천 목록이 이미 있으면 첫 번째 항목을 우선 사용합니다.
        if let suggestion = searchSuggestions.first {
            selectSearchSuggestion(suggestion)
            return
        }

        // 네이버 호출 전에 로컬 시설명/주소 검색으로 먼저 이동할 수 있는지 확인합니다.
        if moveMapToLocalSearchResult(for: query) {
            showSearchSuggestions([])
            return
        }

        Task { [weak self] in
            guard let self else { return }
            let remoteSuggestions = await fetchRemoteSearchSuggestions(for: query)

            await MainActor.run {
                guard let suggestion = remoteSuggestions.first else {
                    self.showSearchFailure(for: query)
                    return
                }

                self.selectSearchSuggestion(suggestion)
            }
        }
    }

    private func moveMapToLocalSearchResult(for query: String) -> Bool {
        guard let result = searchMapSuggestionsUseCase.makeLocalSearchResult(
            query: query,
            facilities: reactor?.currentState.markerFacilities ?? markerFacilities,
            fallbackCoordinate: defaultCoordinate
        ) else {
            return false
        }

        reactor?.action.onNext(.selectFacility(result.selectedFacilityID))
        shouldUpdateListForVisibleMapBounds = true
        errorMessage = nil
        moveCamera(to: result.coordinate, zoom: result.preferredZoom)
        setBottomPanelDetent(.medium, animated: true)
        return true
    }

    private func centerCoordinate(of facilities: [FitnessFacility]) -> GeoCoordinate {
        guard facilities.isEmpty == false else {
            return defaultCoordinate
        }

        let latitude = facilities.map(\.coordinate.latitude).reduce(0, +) / Double(facilities.count)
        let longitude = facilities.map(\.coordinate.longitude).reduce(0, +) / Double(facilities.count)
        return GeoCoordinate(latitude: latitude, longitude: longitude)
    }

    private func showSearchFailure(for query: String) {
        reactor?.action.onNext(.selectFacility(nil))
        showSearchSuggestions([])
        displayedFacilities = []
        errorMessage = "\"\(query)\" 위치를 찾을 수 없습니다."
        isShowingFacilityEmptyState = false
        emptyStateLabel.text = errorMessage
        emptyStateLabel.isHidden = false
        tableView.isHidden = true
        setBottomPanelDetent(.medium, animated: true)
    }

    private func updateDisplayedFacilities() {
        let wasEmpty = displayedFacilities.isEmpty

        if let selectedFacility {
            // 마커를 직접 눌렀을 때는 같은 좌표에 있는 시설과 프로그램을 모두 보여줍니다.
            displayedFacilities = facilities(atSameCoordinateAs: selectedFacility)
        } else {
            displayedFacilities = visibleDisplayFacilitiesInCurrentMapBounds()
        }

        if loadingIndicatorView.isAnimating {
            isShowingFacilityEmptyState = false
            emptyStateLabel.isHidden = true
        } else {
            emptyStateLabel.text = emptyStateMessage()
            isShowingFacilityEmptyState = displayedFacilities.isEmpty && errorMessage == nil
            emptyStateLabel.isHidden = displayedFacilities.isEmpty == false
        }
        tableView.isHidden = displayedFacilities.isEmpty
        tableView.reloadData()

        if isShowingFacilityEmptyState {
            bottomPanelDetent = .collapsed
            mapView.updateBottomPanelHeight(bottomPanelHeight(for: .collapsed))
        } else if wasEmpty && displayedFacilities.isEmpty == false && bottomPanelDetent == .collapsed {
            setBottomPanelDetent(.medium, animated: true)
        }
    }

    private func facilities(atSameCoordinateAs selectedFacility: FitnessFacility) -> [FitnessFacility] {
        let facilityCells = markerFacilities.filter {
            $0.coordinate.isSameLocation(as: selectedFacility.coordinate)
        }

        let selectedFacilityCell = selectedFacility.sourceKind == .facility ? [selectedFacility] : []
        let programCells = allFacilities.filter {
            $0.sourceKind == .program
                && $0.coordinate.isSameLocation(as: selectedFacility.coordinate)
        }

        return uniqueFacilities(selectedFacilityCell + facilityCells + programCells)
    }

    private func relatedPrograms(for facility: FitnessFacility) -> [FitnessFacility] {
        guard let sourceFacilityID = facility.sourceFacilityID else {
            return facility.sourceKind == .program ? [facility] : []
        }

        // 상세 화면의 개설 프로그램은 현재 필터/화면에 보이는 목록뿐 아니라 이미 받아온 전체 후보에서 모읍니다.
        let candidates = unfilteredFacilities + allFacilities + displayedFacilities + [facility]
        let programs = candidates.filter {
            $0.sourceKind == .program && $0.sourceFacilityID == sourceFacilityID
        }

        return uniquePrograms(programs)
    }

    private func uniqueFacilities(_ facilities: [FitnessFacility]) -> [FitnessFacility] {
        var seenIDs = Set<String>()
        return facilities.filter { facility in
            seenIDs.insert(facility.id).inserted
        }
    }

    private func uniquePrograms(_ programs: [FitnessFacility]) -> [FitnessFacility] {
        var seenKeys = Set<String>()
        return programs.filter { program in
            let key = program.sourceProgramID.map { "program-\($0)" } ?? program.id
            return seenKeys.insert(key).inserted
        }
    }

    private func requestProgramsForVisibleMarkerFacilities() {
        // 전체 프로그램을 미리 받지 않고, 현재 지도에 보이는 시설 ID에 대해서만 프로그램을 요청합니다.
        let sourceFacilities = unfilteredMarkerFacilities.isEmpty
            ? markerFacilities
            : unfilteredMarkerFacilities
        let facilityIDs = visibleMarkerFacilitiesInCurrentMapBounds(from: sourceFacilities)
            .compactMap(\.sourceFacilityID)
        guard facilityIDs.isEmpty == false else { return }
        reactor?.action.onNext(.loadProgramsForFacilities(facilityIDs))
    }

    private func visibleDisplayFacilitiesInCurrentMapBounds() -> [FitnessFacility] {
        let visiblePrograms = visibleProgramFacilitiesInCurrentMapBounds()
        guard visiblePrograms.isEmpty,
              shouldShowVisibleFacilityFallback else {
            return visiblePrograms
        }

        // 필터가 전혀 없고 아직 프로그램이 없는 경우에는 빈 모달 대신 시설 셀을 fallback으로 보여줍니다.
        return visibleMarkerFacilitiesInCurrentMapBounds(from: markerFacilities)
            .sorted { $0.distanceInMeters < $1.distanceInMeters }
    }

    private func visibleProgramFacilitiesInCurrentMapBounds() -> [FitnessFacility] {
        guard shouldUpdateListForVisibleMapBounds else {
            return allFacilities.sorted { $0.distanceInMeters < $1.distanceInMeters }
        }

        let visibleSourceIDs = Set(
            visibleMarkerFacilitiesInCurrentMapBounds(from: markerFacilities)
                .compactMap(\.sourceFacilityID)
        )

        return allFacilities
            .filter { facility in
                guard let sourceFacilityID = facility.sourceFacilityID else { return false }
                return visibleSourceIDs.contains(sourceFacilityID)
            }
            .sorted { $0.distanceInMeters < $1.distanceInMeters }
    }

    private var shouldShowVisibleFacilityFallback: Bool {
        guard let state = reactor?.currentState else { return false }
        let searchText = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filter = state.filter

        return searchText.isEmpty
            && filter.categories.isEmpty
            && filter.minimumPrice == nil
            && filter.maximumPrice == nil
            && filter.days.isEmpty
            && filter.timeSlots.isEmpty
    }

    private func visibleMarkerFacilitiesInCurrentMapBounds() -> [FitnessFacility] {
        visibleMarkerFacilitiesInCurrentMapBounds(from: markerFacilities)
    }

    private func visibleMarkerFacilitiesInCurrentMapBounds(from facilities: [FitnessFacility]) -> [FitnessFacility] {
        let visibleBounds = naverMapView.mapView.contentBounds
        return facilities.filter { facility in
            let position = NMGLatLng(
                lat: facility.coordinate.latitude,
                lng: facility.coordinate.longitude
            )
            return visibleBounds.hasPoint(position)
        }
    }

    private func emptyStateMessage() -> String {
        if let errorMessage {
            return errorMessage
        }

        // 지도 안에 시설 자체가 없는 경우와, 시설은 있지만 필터 조건에 맞지 않는 경우를 구분합니다.
        let visibleMarkerFacilities = visibleMarkerFacilitiesInCurrentMapBounds(from: unfilteredMarkerFacilities)
        if visibleMarkerFacilities.isEmpty {
            return "주변에 시설, 프로그램이 없습니다."
        }

        return "조건에 맞는 프로그램이 없습니다."
    }

    private func isFacilityVisibleInCurrentMapBounds(_ facility: FitnessFacility) -> Bool {
        naverMapView.mapView.contentBounds.hasPoint(
            NMGLatLng(
                lat: facility.coordinate.latitude,
                lng: facility.coordinate.longitude
            )
        )
    }

    private func bottomPanelHeight(for detent: BottomPanelDetent) -> CGFloat {
        switch detent {
        case .collapsed:
            return MapMetric.collapsedBottomPanelHeight

        case .medium:
            return min(MapMetric.mediumBottomPanelHeight, bottomPanelHeight(for: .expanded))

        case .expanded:
            if let maximumHeight = mapView.maximumBottomPanelHeight(
                currentLocationButtonMinimumGap: MapMetric.currentLocationButtonMinimumGap
            ) {
                // 확장 상태에서도 현재 위치 버튼과 하단 패널이 겹치지 않도록 상한을 둡니다.
                return max(MapMetric.collapsedBottomPanelHeight, maximumHeight)
            }

            let topInset = view.safeAreaInsets.top + MapMetric.expandedPanelTopInset
            return max(MapMetric.collapsedBottomPanelHeight, view.bounds.height - topInset)
        }
    }

    private func setBottomPanelDetent(_ detent: BottomPanelDetent, animated: Bool) {
        bottomPanelDetent = detent
        let height = bottomPanelHeight(for: detent)
        mapView.updateBottomPanelHeight(height)

        let animations = {
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(
                withDuration: MapAnimationMetric.bottomPanelDuration,
                delay: 0,
                usingSpringWithDamping: MapAnimationMetric.bottomPanelSpringDamping,
                initialSpringVelocity: MapAnimationMetric.bottomPanelInitialVelocity,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: animations
            )
        } else {
            animations()
        }
    }

    private func nearestBottomPanelDetent(for height: CGFloat, velocityY: CGFloat) -> BottomPanelDetent {
        if velocityY < -MapMetric.detentVelocityThreshold {
            return height > bottomPanelHeight(for: .medium) ? .expanded : .medium
        }

        if velocityY > MapMetric.detentVelocityThreshold {
            return height < bottomPanelHeight(for: .medium) ? .collapsed : .medium
        }

        let detents: [BottomPanelDetent] = [.collapsed, .medium, .expanded]
        return detents.min {
            abs(bottomPanelHeight(for: $0) - height) < abs(bottomPanelHeight(for: $1) - height)
        } ?? .collapsed
    }

    @objc private func handleBottomPanelPan(_ gesture: UIPanGestureRecognizer) {
        let collapsedHeight = bottomPanelHeight(for: .collapsed)
        let expandedHeight = bottomPanelHeight(for: .expanded)
        let translationY = gesture.translation(in: view).y

        switch gesture.state {
        case .began:
            bottomPanelHeightAtPanStart = bottomPanelHeight(for: bottomPanelDetent)

        case .changed:
            let targetHeight = bottomPanelHeightAtPanStart - translationY
            let clampedHeight = min(max(targetHeight, collapsedHeight), expandedHeight)
            mapView.updateBottomPanelHeight(clampedHeight)
            view.layoutIfNeeded()

        case .ended, .cancelled, .failed:
            let currentHeight = bottomPanelHeightAtPanStart - translationY
            let velocityY = gesture.velocity(in: view).y
            let detent = nearestBottomPanelDetent(for: currentHeight, velocityY: velocityY)
            setBottomPanelDetent(detent, animated: true)

        default:
            break
        }
    }

    private func renderMarkers(_ facilities: [FitnessFacility]) {
        let presentationStyle = markerPresentationStyle
        renderedMarkerPresentationStyle = presentationStyle
        markers.forEach { $0.mapView = nil }

        // 가까이서는 개별 gym 마커, 중간 줌에서는 같은 좌표 묶음, 멀리서는 근처 시설 클러스터를 사용합니다.
        switch presentationStyle {
        case .gym:
            markers = makeGymMarkers(from: facilities)
        case .sameCoordinateCount:
            markers = makeCountMarkers(from: makeSameCoordinateMarkerGroups(from: facilities))
        case let .nearbyCount(clusterGridSizeMeters):
            markers = makeCountMarkers(
                from: makeNearbyMarkerGroups(
                    from: facilities,
                    clusterGridSizeMeters: clusterGridSizeMeters
                ),
                opensClusterOnTap: true
            )
        }
    }

    private var markerPresentationStyle: MarkerPresentationStyle {
        let zoomLevel = naverMapView.mapView.zoomLevel

        // 줌 레벨 기준은 UI 가독성 기준입니다. 숫자를 바꾸면 마커 전환 시점이 함께 바뀝니다.
        if zoomLevel >= MapZoomLevel.gymMarkerMinimum {
            return .gym
        }

        if zoomLevel >= MapZoomLevel.sameCoordinateCountMarkerMinimum {
            return .sameCoordinateCount
        }

        return .nearbyCount(clusterGridSizeMeters: nearbyClusterGridSizeMeters(for: zoomLevel))
    }

    private func refreshMarkersIfNeededForCurrentZoom() {
        let currentStyle = markerPresentationStyle
        guard renderedMarkerPresentationStyle != currentStyle else { return }
        renderMarkers(markerFacilities)
    }

    private func makeGymMarkers(from facilities: [FitnessFacility]) -> [NMFMarker] {
        let markerIconImage = makeGymMarkerImage()
        return facilities.map { facility in
            let marker = NMFMarker(
                position: NMGLatLng(
                    lat: facility.coordinate.latitude,
                    lng: facility.coordinate.longitude
                )
            )
            marker.iconImage = NMFOverlayImage(image: markerIconImage)
            marker.width = markerIconImage.size.width
            marker.height = markerIconImage.size.height
            marker.anchor = CGPoint(x: 0.5, y: 0.5)
            marker.touchHandler = { [weak self] _ in
                guard let self else { return true }
                // 같은 좌표에 시설/프로그램이 여러 개 있을 수 있어 해당 좌표의 모든 시설 ID로 프로그램을 요청합니다.
                let facilityIDs = self.markerFacilities
                    .filter { $0.coordinate.isSameLocation(as: facility.coordinate) }
                    .compactMap(\.sourceFacilityID)
                self.reactor?.action.onNext(.loadProgramsForFacilities(facilityIDs))
                self.reactor?.action.onNext(.selectFacility(facility.id))
                self.moveCamera(to: facility.coordinate)
                return true
            }
            marker.mapView = naverMapView.mapView
            return marker
        }
    }

    private func makeCountMarkers(
        from markerGroups: [FacilityMarkerGroup],
        opensClusterOnTap: Bool = false
    ) -> [NMFMarker] {
        return markerGroups.compactMap { group in
            guard let primaryFacility = group.facilities.first else { return nil }

            let markerIconImage = makeFacilityCountMarkerImage(for: group.facilities)
            let marker = NMFMarker(
                position: NMGLatLng(
                    lat: group.coordinate.latitude,
                    lng: group.coordinate.longitude
                )
            )
            marker.iconImage = NMFOverlayImage(image: markerIconImage)
            marker.width = markerIconImage.size.width
            marker.height = markerIconImage.size.height
            marker.anchor = CGPoint(x: 0.5, y: 0.5)
            marker.touchHandler = { [weak self] _ in
                guard let self else { return true }
                let facilityIDs = group.facilities.compactMap(\.sourceFacilityID)
                self.reactor?.action.onNext(.loadProgramsForFacilities(facilityIDs))
                if opensClusterOnTap, group.facilities.count > 1 {
                    // 먼 줌의 클러스터를 누르면 바로 특정 시설을 고르지 않고, 묶음 중심으로 확대해 선택 범위를 좁힙니다.
                    self.reactor?.action.onNext(.selectFacility(nil))
                    self.shouldUpdateListForVisibleMapBounds = true
                    self.moveCamera(to: group.coordinate, zoom: MapZoomLevel.sameCoordinateCountMarkerMinimum)
                } else {
                    self.reactor?.action.onNext(.selectFacility(primaryFacility.id))
                    self.moveCamera(to: group.coordinate)
                }
                return true
            }
            marker.mapView = naverMapView.mapView
            return marker
        }
    }

    private func makeGymMarkerImage() -> UIImage {
        let size = CGSize(width: 34, height: 34)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let bounds = CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)
            let circlePath = UIBezierPath(ovalIn: bounds)
            UIColor.systemBackground.withAlphaComponent(0.8).setFill()
            circlePath.fill()
            UIColor.primary100.setStroke()
            circlePath.lineWidth = 1
            circlePath.stroke()

            guard let icon = UIImage(named: "gym")?.withRenderingMode(.alwaysOriginal) else { return }
            let iconRect = CGRect(x: 9, y: 9, width: 16, height: 16)
            icon.draw(in: iconRect, blendMode: .normal, alpha: 1)
        }
    }

    private func makeSameCoordinateMarkerGroups(from facilities: [FitnessFacility]) -> [FacilityMarkerGroup] {
        facilities.reduce(into: []) { groups, facility in
            if let index = groups.firstIndex(where: { $0.coordinate.isSameLocation(as: facility.coordinate) }) {
                groups[index].facilities.append(facility)
            } else {
                groups.append(FacilityMarkerGroup(coordinate: facility.coordinate, facilities: [facility]))
            }
        }
    }

    private func makeNearbyMarkerGroups(
        from facilities: [FitnessFacility],
        clusterGridSizeMeters: Int
    ) -> [FacilityMarkerGroup] {
        // 지도 라이브러리 클러스터링 대신 미터 단위 격자로 묶어 카테고리별 숫자 마커를 직접 만듭니다.
        let gridSize = Double(clusterGridSizeMeters)
        let groupedFacilities = Dictionary(grouping: facilities) { facility in
            nearbyClusterKey(for: facility.coordinate, gridSizeMeters: gridSize)
        }

        return groupedFacilities.values.map { facilities in
            FacilityMarkerGroup(
                coordinate: centerCoordinate(of: facilities),
                facilities: facilities
            )
        }
    }

    private func nearbyClusterKey(for coordinate: GeoCoordinate, gridSizeMeters: Double) -> String {
        let latitudeMeters = coordinate.latitude * 111_320
        let longitudeMeters = coordinate.longitude
            * 111_320
            * cos(coordinate.latitude * .pi / 180)
        let latitudeIndex = Int(floor(latitudeMeters / gridSizeMeters))
        let longitudeIndex = Int(floor(longitudeMeters / gridSizeMeters))
        return "\(latitudeIndex)-\(longitudeIndex)"
    }

    private func nearbyClusterGridSizeMeters(for zoomLevel: Double) -> Int {
        switch zoomLevel {
        case ..<8:
            return 20_000
        case ..<9:
            return 14_000
        case ..<10:
            return 10_000
        case ..<11:
            return 7_000
        case ..<12:
            return 5_000
        case ..<13:
            return 3_000
        default:
            return 1_800
        }
    }

    private func makeFacilityCountMarkerImage(for facilities: [FitnessFacility]) -> UIImage {
        FacilityCountMarkerView(items: makeFacilityCountMarkerItems(for: facilities)).renderedImage()
    }

    private func makeFacilityCountMarkerItems(for facilities: [FitnessFacility]) -> [FacilityCountMarkerView.Item] {
        markerIconCounts(for: facilities).map { iconName, count in
            return FacilityCountMarkerView.Item(
                icon: UIImage(named: iconName)?.withRenderingMode(.alwaysOriginal)
                    ?? UIImage(named: "gym")?.withRenderingMode(.alwaysOriginal),
                count: count
            )
        }
    }

    private func markerIconCounts(for facilities: [FitnessFacility]) -> [(iconName: String, count: Int)] {
        let countsByIconName = facilities.reduce(into: [String: Int]()) { counts, facility in
            counts[facility.category.markerIconName, default: 0] += 1
        }
        var seenIconNames = Set<String>()

        // FacilityCategory 순서를 유지해 마커 안의 아이콘 표시 순서가 매번 흔들리지 않게 합니다.
        return FacilityCategory.allCases.compactMap { category in
            let iconName = category.markerIconName
            guard seenIconNames.insert(iconName).inserted,
                  let count = countsByIconName[iconName] else { return nil }
            return (iconName: iconName, count: count)
        }
    }

    private func moveCameraToUserLocation() {
        if locationService.isAuthorizationDeniedOrRestricted {
            presentLocationPermissionAlert()
            return
        }

        guard let coordinate = currentUserCoordinate else {
            locationService.requestCurrentLocation()
            return
        }
        moveCamera(to: coordinate)
    }

    private func updateCurrentLocation(_ coordinate: GeoCoordinate) {
        currentUserCoordinate = coordinate
        naverMapView.mapView.locationOverlay.location = NMGLatLng(
            lat: coordinate.latitude,
            lng: coordinate.longitude
        )
        naverMapView.mapView.locationOverlay.hidden = false
        moveCamera(to: coordinate)

        let query = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if query.isEmpty == false {
            updateSearchSuggestions(for: query)
        }
    }

    private func moveCamera(to coordinate: GeoCoordinate, zoom: Double? = nil) {
        let target = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        let cameraUpdate = if let zoom {
            NMFCameraUpdate(scrollTo: target, zoomTo: zoom)
        } else {
            NMFCameraUpdate(scrollTo: target)
        }
        cameraUpdate.animation = .easeIn
        naverMapView.mapView.moveCamera(cameraUpdate)
    }

    @objc private func didTapCurrentLocationButton() {
        moveCameraToUserLocation()
    }

    private func presentLocationPermissionAlert() {
        guard presentedViewController == nil else { return }

        let alertController = UIAlertController(
            title: "현재 위치를 보려면 위치 권한이 필요해요.",
            message: nil,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(settingsURL) else { return }
                UIApplication.shared.open(settingsURL)
            }
        )
        alertController.addAction(
            UIAlertAction(title: "기본 위치로 보기", style: .cancel)
        )

        present(alertController, animated: true)
    }

    private var searchDistanceReferenceCoordinate: GeoCoordinate {
        currentUserCoordinate ?? defaultCoordinate
    }

}

extension MapViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === searchSuggestionTableView {
            return searchSuggestions.count
        }

        return displayedFacilities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === searchSuggestionTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SearchSuggestionCell.reuseIdentifier,
                for: indexPath
            ) as? SearchSuggestionCell else {
                return UITableViewCell()
            }

            cell.configure(with: searchSuggestions[indexPath.row])
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FacilityListCell.reuseIdentifier,
            for: indexPath
        ) as? FacilityListCell else {
            return UITableViewCell()
        }

        let facility = displayedFacilities[indexPath.row]
        cell.configure(with: facility)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === searchSuggestionTableView {
            selectSearchSuggestion(searchSuggestions[indexPath.row])
            return
        }

        let facility = displayedFacilities[indexPath.row]
        reactor?.action.onNext(.selectFacility(facility.id))
        steps.accept(AppStep.mapFacilityDetail(facility, relatedPrograms: relatedPrograms(for: facility)))
    }
}

extension MapViewController: NMFMapViewCameraDelegate {
    func mapViewCameraIdle(_ mapView: NMFMapView) {
        shouldUpdateListForVisibleMapBounds = true
        refreshMarkersIfNeededForCurrentZoom()
        requestProgramsForVisibleMarkerFacilities()

        if let selectedFacility,
           isFacilityVisibleInCurrentMapBounds(selectedFacility) == false {
            reactor?.action.onNext(.selectFacility(nil))
            return
        }

        updateDisplayedFacilities()
    }
}

extension MapViewController: NMFMapViewTouchDelegate {
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        showSearchSuggestions([])
        shouldUpdateListForVisibleMapBounds = true

        guard selectedFacility != nil else {
            updateDisplayedFacilities()
            return
        }

        reactor?.action.onNext(.selectFacility(nil))
    }
}

extension MapViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer.view === bottomPanelView else {
            return true
        }

        guard isShowingFacilityEmptyState == false else {
            return false
        }

        let location = gestureRecognizer.location(in: bottomPanelView)
        return location.y <= 56
    }
}

private extension GeoCoordinate {
    func isSameLocation(as other: GeoCoordinate) -> Bool {
        abs(latitude - other.latitude) < 0.000001
            && abs(longitude - other.longitude) < 0.000001
    }
}

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

final class MapViewController: BaseViewController<MapReactor> {
    private let mapView = MapView()
    private let searchMapSuggestionsUseCase: SearchMapSuggestionsUseCase
    private let markerRenderer = MapMarkerRenderer()

    private var allFacilities: [FitnessFacility] = []
    private var unfilteredFacilities: [FitnessFacility] = []
    private var unfilteredMarkerFacilities: [FitnessFacility] = []
    private var markerFacilities: [FitnessFacility] = []
    private var displayedFacilities: [FitnessFacility] = []
    private var searchSuggestions: [MapSearchSuggestion] = []
    private var selectedFacility: FitnessFacility?
    private var shouldUpdateListForVisibleMapBounds = false
    private var bottomPanelDetent: BottomPanelDetent = .collapsed
    private var bottomPanelHeightAtPanStart: CGFloat = MapMetric.collapsedBottomPanelHeight
    private var isShowingFacilityEmptyState = false
    private var emptyStateMessage = "조건에 맞는 프로그램이 없습니다."
    private var hasEmptyStateError = false
    private let locationService = LocationService()
    private var currentUserCoordinate: GeoCoordinate?
    private let defaultCoordinate = GeoCoordinate(latitude: 37.576022, longitude: 126.976900) // 기본 좌표 광화문

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
        configureMarkerRenderer()
        configureTraitChangeHandling()
        mapView.tableView.dataSource = self
        mapView.tableView.delegate = self
        mapView.searchSuggestionTableView.dataSource = self
        mapView.searchSuggestionTableView.delegate = self
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
        mapView.searchTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .skip(1)
            .map(MapReactor.Action.searchTextChanged)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        mapView.searchTextField.rx.search
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .subscribe(onNext: { [weak self] query in
                self?.moveMapForSearchQuery(query)
            })
            .disposed(by: disposeBag)

        mapView.searchTextField.rx.text.orEmpty
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
                guard let self else { return }
                self.markerFacilities = facilities
                self.markerRenderer.render(facilities, on: self.mapView.naverMapView.mapView)
                self.syncVisibleFacilityIDsWithReactor()
                self.requestProgramsForVisibleMarkerFacilities()
                self.updateDisplayedFacilities()
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.allMarkerFacilities)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] facilities in
                guard let self else { return }
                self.unfilteredMarkerFacilities = facilities
                self.syncVisibleFacilityIDsWithReactor()
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
                isLoading ? self?.mapView.loadingIndicatorView.startAnimating() : self?.mapView.loadingIndicatorView.stopAnimating()
                self?.updateDisplayedFacilities()
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.emptyStateMessage)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.emptyStateMessage = message
                self?.updateDisplayedFacilities()
            })
            .disposed(by: disposeBag)

        reactor.state
            .map(\.hasEmptyStateError)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] hasError in
                self?.hasEmptyStateError = hasError
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
                self?.mapView.missingKeyView.isHidden = isConfigured
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
        mapView.bottomPanelView.addGestureRecognizer(panGesture)
    }

    private func configureFilterButtonActions() {
        mapView.allFilterButton.addAction(UIAction { [weak self] _ in
            self?.presentFilterModal(mode: .all)
        }, for: .touchUpInside)

        mapView.aiButton.addAction(UIAction { [weak self] _ in
            self?.reactor?.action.onNext(.toggleAIRecommendation)
        }, for: .touchUpInside)

        mapView.categoryButton.addAction(UIAction { [weak self] _ in
            self?.presentFilterModal(mode: .category)
        }, for: .touchUpInside)
        mapView.dayButton.addAction(UIAction { [weak self] _ in
            self?.presentFilterModal(mode: .schedule)
        }, for: .touchUpInside)
        mapView.timeButton.addAction(UIAction { [weak self] _ in
            self?.presentFilterModal(mode: .schedule)
        }, for: .touchUpInside)
        mapView.priceButton.addAction(UIAction { [weak self] _ in
            self?.presentFilterModal(mode: .price)
        }, for: .touchUpInside)
    }

    private func configureMap() {
        mapView.naverMapView.showZoomControls = false
        mapView.naverMapView.showLocationButton = false
        mapView.naverMapView.mapView.addCameraDelegate(delegate: self)
        mapView.naverMapView.mapView.touchDelegate = self
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
        mapView.currentLocationButton.addTarget(self, action: #selector(didTapCurrentLocationButton), for: .touchUpInside)
    }

    private func configureMarkerRenderer() {
        markerRenderer.didTapFacilityMarker = { [weak self] facility in
            guard let self else { return }
            let facilityIDs = self.markerFacilities
                .filter { $0.coordinate.isSameLocation(as: facility.coordinate) }
                .compactMap(\.sourceFacilityID)
            self.reactor?.action.onNext(.loadProgramsForFacilities(facilityIDs))
            self.reactor?.action.onNext(.selectFacility(facility.id))
            self.moveCamera(to: facility.coordinate)
        }

        markerRenderer.didTapFacilityGroupMarker = { [weak self] group, opensClusterOnTap in
            guard let self,
                  let primaryFacility = group.facilities.first else { return }

            let facilityIDs = group.facilities.compactMap(\.sourceFacilityID)
            self.reactor?.action.onNext(.loadProgramsForFacilities(facilityIDs))

            if opensClusterOnTap, group.facilities.count > 1 {
                self.reactor?.action.onNext(.selectFacility(nil))
                self.shouldUpdateListForVisibleMapBounds = true
                self.moveCamera(to: group.coordinate, zoom: MapMarkerRenderer.clusterExpansionZoom)
            } else {
                self.reactor?.action.onNext(.selectFacility(primaryFacility.id))
                self.moveCamera(to: group.coordinate)
            }
        }
    }

    private func configureTraitChangeHandling() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: Self, _) in
            viewController.applyMapAppearance()
            viewController.markerRenderer.render(
                viewController.markerFacilities,
                on: viewController.mapView.naverMapView.mapView
            )
        }
    }

    private func applyMapAppearance() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        mapView.naverMapView.mapView.isNightModeEnabled = isDarkMode
        mapView.naverMapView.backgroundColor = .systemBackground
        mapView.naverMapView.mapView.backgroundColor = .systemBackground
    }

    private func presentFilterModal(mode: MapFilterMode) {
        guard let filter = reactor?.currentState.filter else { return }
        let priceSamples = (reactor?.currentState.allFacilities ?? allFacilities).map(\.price)
        steps.accept(AppStep.mapFilter(filter, priceSamples: priceSamples, mode: mode))
    }

    private func updateSearchSuggestions(for query: String) {
        guard query.isEmpty == false else {
            showSearchSuggestions([])
            return
        }

        showSearchSuggestions(makeLocalSearchSuggestions(for: query))
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

    private func showSearchSuggestions(_ suggestions: [MapSearchSuggestion]) {
        searchSuggestions = suggestions
        mapView.searchSuggestionTableView.reloadData()
        mapView.searchSuggestionTableView.isHidden = suggestions.isEmpty
        mapView.updateSearchSuggestionHeight(
            min(CGFloat(suggestions.count) * SearchSuggestionCell.rowHeight, MapMetric.searchSuggestionMaximumHeight)
        )
    }

    private func selectSearchSuggestion(_ suggestion: MapSearchSuggestion) {
        mapView.searchTextField.text = suggestion.title
        showSearchSuggestions([])
        view.endEditing(true)
        reactor?.action.onNext(.selectFacility(suggestion.facilityID))
        reactor?.action.onNext(.setSearchErrorMessage(nil))
        shouldUpdateListForVisibleMapBounds = true
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
        reactor?.action.onNext(.setSearchErrorMessage(nil))
        shouldUpdateListForVisibleMapBounds = true
        moveCamera(to: result.coordinate, zoom: result.preferredZoom)
        setBottomPanelDetent(.medium, animated: true)
        return true
    }

    private func showSearchFailure(for query: String) {
        let message = "\"\(query)\" 위치를 찾을 수 없습니다."
        reactor?.action.onNext(.selectFacility(nil))
        reactor?.action.onNext(.setSearchErrorMessage(message))
        showSearchSuggestions([])
        displayedFacilities = []
        emptyStateMessage = message
        hasEmptyStateError = true
        isShowingFacilityEmptyState = false
        mapView.emptyStateLabel.text = message
        mapView.emptyStateLabel.isHidden = false
        mapView.tableView.isHidden = true
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

        if mapView.loadingIndicatorView.isAnimating {
            isShowingFacilityEmptyState = false
            mapView.emptyStateLabel.isHidden = true
        } else {
            mapView.emptyStateLabel.text = emptyStateMessage
            isShowingFacilityEmptyState = displayedFacilities.isEmpty && hasEmptyStateError == false
            mapView.emptyStateLabel.isHidden = displayedFacilities.isEmpty == false
        }
        mapView.tableView.isHidden = displayedFacilities.isEmpty
        mapView.tableView.reloadData()

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
        let facilityIDs = visibleMarkerFacilitiesForMapContext()
            .compactMap(\.sourceFacilityID)
        guard facilityIDs.isEmpty == false else { return }
        reactor?.action.onNext(.loadProgramsForFacilities(facilityIDs))
    }

    private func visibleDisplayFacilitiesInCurrentMapBounds() -> [FitnessFacility] {
        let visibleFacilities = visibleFacilityCellsInCurrentMapBounds()
        let visiblePrograms = visibleProgramFacilitiesInCurrentMapBounds()

        if shouldIncludeFacilityCellsInVisibleList {
            return sortByCurrentRecommendationState(uniqueFacilities(visibleFacilities + visiblePrograms))
        }

        guard visiblePrograms.isEmpty,
              shouldShowVisibleFacilityFallback else {
            return visiblePrograms
        }

        // 필터가 전혀 없고 아직 프로그램이 없는 경우에는 빈 모달 대신 시설 셀을 fallback으로 보여줍니다.
        return visibleFacilities
    }

    private func visibleFacilityCellsInCurrentMapBounds() -> [FitnessFacility] {
        let sourceFacilities = unfilteredMarkerFacilities.isEmpty
            ? markerFacilities
            : unfilteredMarkerFacilities

        let visibleFacilities = visibleMarkerFacilitiesInCurrentMapBounds(from: sourceFacilities)
            .filter(matchesCurrentSearchAndFilter)

        return sortByCurrentRecommendationState(visibleFacilities)
    }

    private func visibleProgramFacilitiesInCurrentMapBounds() -> [FitnessFacility] {
        guard shouldUpdateListForVisibleMapBounds else {
            return sortByCurrentRecommendationState(allFacilities)
        }

        let visibleSourceIDs = Set(
            visibleMarkerFacilitiesInCurrentMapBounds(from: markerFacilities)
                .compactMap(\.sourceFacilityID)
        )

        let visiblePrograms = allFacilities
            .filter { facility in
                guard let sourceFacilityID = facility.sourceFacilityID else { return false }
                return visibleSourceIDs.contains(sourceFacilityID)
            }

        return sortByCurrentRecommendationState(visiblePrograms)
    }

    private func sortByCurrentRecommendationState(_ facilities: [FitnessFacility]) -> [FitnessFacility] {
        guard reactor?.currentState.filter.isAIRecommendationEnabled == true else {
            return facilities.sorted { $0.distanceInMeters < $1.distanceInMeters }
        }

        return facilities.sorted {
            if $0.matchingRate == $1.matchingRate {
                return $0.distanceInMeters < $1.distanceInMeters
            }
            return $0.matchingRate > $1.matchingRate
        }
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

    private var shouldIncludeFacilityCellsInVisibleList: Bool {
        guard let state = reactor?.currentState else { return false }
        let searchText = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filter = state.filter

        return searchText.isEmpty == false
            || filter.categories.isEmpty == false
            || filter.minimumPrice != nil
            || filter.maximumPrice != nil
            || filter.days.isEmpty == false
            || filter.timeSlots.isEmpty == false
    }

    private func matchesCurrentSearchAndFilter(_ facility: FitnessFacility) -> Bool {
        guard let state = reactor?.currentState else { return true }
        let normalizedSearchText = state.searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let filter = state.filter

        let matchesSearch = normalizedSearchText.isEmpty
            || facility.name.lowercased().contains(normalizedSearchText)
            || facility.address.lowercased().contains(normalizedSearchText)
            || facility.category.title.lowercased().contains(normalizedSearchText)
        let matchesCategory = filter.categories.isEmpty || filter.categories.contains(facility.category)
        let matchesKnownPriceRange = (filter.minimumPrice.map { facility.price >= $0 } ?? true)
            && (filter.maximumPrice.map { facility.price <= $0 } ?? true)
        let matchesPrice = facility.priceText == "상세 정보 확인" || matchesKnownPriceRange
        let matchesDay = filter.days.isEmpty
            || Set(facility.availableDays).isDisjoint(with: filter.days) == false
        let matchesTime = filter.timeSlots.isEmpty
            || filter.timeSlots.contains { facility.availableTimeRange.overlaps($0.range) }

        return matchesSearch && matchesCategory && matchesPrice && matchesDay && matchesTime
    }

    private func visibleMarkerFacilitiesForMapContext() -> [FitnessFacility] {
        let sourceFacilities = unfilteredMarkerFacilities.isEmpty
            ? markerFacilities
            : unfilteredMarkerFacilities
        return visibleMarkerFacilitiesInCurrentMapBounds(from: sourceFacilities)
    }

    private func syncVisibleFacilityIDsWithReactor() {
        let visibleFacilityIDs = visibleMarkerFacilitiesForMapContext()
            .map { $0.sourceFacilityID ?? $0.id }
        reactor?.action.onNext(.updateVisibleFacilityIDs(visibleFacilityIDs))
    }

    private func visibleMarkerFacilitiesInCurrentMapBounds(from facilities: [FitnessFacility]) -> [FitnessFacility] {
        let visibleBounds = mapView.naverMapView.mapView.contentBounds
        return facilities.filter { facility in
            let position = NMGLatLng(
                lat: facility.coordinate.latitude,
                lng: facility.coordinate.longitude
            )
            return visibleBounds.hasPoint(position)
        }
    }

    private func isFacilityVisibleInCurrentMapBounds(_ facility: FitnessFacility) -> Bool {
        mapView.naverMapView.mapView.contentBounds.hasPoint(
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
        mapView.naverMapView.mapView.locationOverlay.location = NMGLatLng(
            lat: coordinate.latitude,
            lng: coordinate.longitude
        )
        mapView.naverMapView.mapView.locationOverlay.hidden = false
        moveCamera(to: coordinate)

        let query = mapView.searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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
        mapView.naverMapView.mapView.moveCamera(cameraUpdate)
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
        if tableView === mapView.searchSuggestionTableView {
            return searchSuggestions.count
        }

        return displayedFacilities.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === mapView.searchSuggestionTableView {
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
        if tableView === mapView.searchSuggestionTableView {
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
        markerRenderer.refreshIfNeeded(for: markerFacilities, on: self.mapView.naverMapView.mapView)
        syncVisibleFacilityIDsWithReactor()
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
        guard gestureRecognizer.view === mapView.bottomPanelView else {
            return true
        }

        guard isShowingFacilityEmptyState == false else {
            return false
        }

        let location = gestureRecognizer.location(in: mapView.bottomPanelView)
        return location.y <= 56
    }
}

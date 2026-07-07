//
//  LocationService.swift
//  WhereToFit
//
//  Created by 김주희 on 6/4/26.
//

import CoreLocation

final class LocationService: NSObject {
    var locationUpdated: ((CLLocationCoordinate2D) -> Void)?
    var locationUnavailable: (() -> Void)?

    private let locationManager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }

    var isAuthorizationDeniedOrRestricted: Bool {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            return true
        case .notDetermined, .authorizedAlways, .authorizedWhenInUse:
            return false
        @unknown default:
            return true
        }
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCurrentLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied, .restricted:
            locationUnavailable?()
        @unknown default:
            locationUnavailable?()
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            locationUnavailable?()
        case .notDetermined:
            return
        @unknown default:
            locationUnavailable?()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        locationUpdated?(location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationUnavailable?()
    }
}

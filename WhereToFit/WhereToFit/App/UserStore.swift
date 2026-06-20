//
//  UserStore.swift
//  WhereToFit
//
//  Created by 변예린 on 6/20/26.
//

import RxSwift
import RxRelay

protocol UserStoreProtocol {
    var userProfile: Observable<UserProfile?> { get }
    var currentLocation: Observable<UserLocation?> { get }
    
    func setProfile(_ profile: UserProfile?)
    func setCurrnetLocation(_ location: UserLocation)
    func clear()
}

final class UserStore: UserStoreProtocol {
    private let profileRelay = BehaviorRelay<UserProfile?>(value: nil)
    private let currentLocationRelay = BehaviorRelay<UserLocation?>(value: nil)
    
    var userProfile: Observable<UserProfile?> {
        profileRelay.asObservable()
    }
    
    var currentLocation: Observable<UserLocation?> {
        currentLocationRelay.asObservable()
    }
    
    func setProfile(_ profile: UserProfile?) {
        <#code#>
    }
    
    func setCurrentLocation(_ location: UserLocation) {
        
    }
    
    func clear() {
        profileRelay.accept(nil)
        currentLocationRelay.accept(nil)
    }
}

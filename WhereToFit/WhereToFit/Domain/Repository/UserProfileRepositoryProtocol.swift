//
//  UserProfileRepositoryProtocol.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/18/26.
//

import Foundation
import RxSwift

protocol UserProfileRepositoryProtocol {
    func fetchUserProfile() -> Single<UserProfile?>
    func saveUserProfile(_ profile: UserProfile) -> Single<UserProfile>
}

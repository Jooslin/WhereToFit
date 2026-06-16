//
//  HomeLocationView.swift
//  WhereToFit
//
//  Created by 변예린 on 6/12/26.
//

import UIKit

final class HomeLocationView: UIView {
    let titleView = TitleView(text: "위치 지정", leftButtonImage: .arrowLeft, rightButtonImage: .edit)
    let searchBar = SearchBar(placeholder: "주소로 검색하기")
}

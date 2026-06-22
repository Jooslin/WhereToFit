//
//  BottomSheetSwipeDismissHandler.swift
//  WhereToFit
//
//  Created by Yeseul Jang on 6/21/26.
//

import UIKit

final class BottomSheetSwipeDismissHandler: NSObject {
    var onDismiss: (() -> Void)?

    private weak var sheetView: UIView?
    private let dismissThreshold: CGFloat = 120
    private let velocityThreshold: CGFloat = 900

    init(sheetView: UIView) {
        self.sheetView = sheetView
        super.init()

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sheetView.addGestureRecognizer(panGesture)
    }
}

private extension BottomSheetSwipeDismissHandler {
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let sheetView else { return }

        let translationY = max(0, gesture.translation(in: sheetView).y)
        let velocityY = gesture.velocity(in: sheetView).y

        switch gesture.state {
        case .changed:
            sheetView.transform = CGAffineTransform(translationX: 0, y: translationY)

        case .ended, .cancelled:
            if translationY > dismissThreshold || velocityY > velocityThreshold {
                onDismiss?()
                return
            }

            UIView.animate(withDuration: 0.2) {
                sheetView.transform = .identity
            }

        default:
            break
        }
    }
}

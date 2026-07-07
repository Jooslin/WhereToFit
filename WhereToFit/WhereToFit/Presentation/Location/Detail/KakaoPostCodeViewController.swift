//
//  KakaoPostCodeViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/15/26.
//

import UIKit
import WebKit
import SnapKit

final class KakaoPostCodeViewController: UIViewController {
    var webView: WKWebView?
    let indicator = UIActivityIndicatorView(style: .medium) // webView 로딩시 보여줄 뷰
    var onSelectAddress: ((String) -> Void)? // 사용자가 선택한 주소를 전달할 클로저
    
    let contentController = WKUserContentController() // JavaScript가 메세지를 post하고 유저의 스크립트를 webview에 주입할 수 있도록 함
    
    @MainActor deinit {
        contentController.removeScriptMessageHandler(forName: "callBackHandler")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.gestureRecognizers?.forEach {
            view.removeGestureRecognizer($0)
        }
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        contentController.add(WeakScriptMessageHandler(self), name: "callBackHandler")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
        
        guard let url = URL(string: "https://devbambu.github.io/KakaoPostCode/"),
              let webView else { return }
        let request = URLRequest(url: url)
        webView.load(request)
        indicator.startAnimating()
        
        // setLayout
        view.addSubview(webView)
        webView.addSubview(indicator)
        
        webView.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(465)
            $0.centerY.equalToSuperview()
        }
        
        indicator.snp.makeConstraints {
            $0.center.equalTo(webView.snp.center)
        }
        
        webView.layer.cornerRadius = 16
        webView.clipsToBounds = true
        
        // 제스처 설정 - 여백 탭시 dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func didTapBackground() {
        dismiss(animated: false)
    }
}

// JavaScript가 보내는 메세지를 수신하기 위한 프로토콜 채택
extension KakaoPostCodeViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        var address = ""
        if let data = message.body as? [String: Any] {
            address = data["roadAddress"] as? String ?? ""
        } // 도로명주소 가져옴
        
        dismiss(animated: false) { [onSelectAddress] in
            onSelectAddress?(address)
        }
    }
}

// webView 로딩 시 inidicator를 표시하기 위한 프로토콜 채택
extension KakaoPostCodeViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        indicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        indicator.stopAnimating()
    }
}

extension KakaoPostCodeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let webView else { return true }
        guard let touchView = touch.view else { return true }
        return !touchView.isDescendant(of: webView)
    }
}

final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var delegate: WKScriptMessageHandler?
    
    init(_ delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

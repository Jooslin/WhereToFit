//
//  KakaoPostCodeViewController.swift
//  WhereToFit
//
//  Created by 변예린 on 6/15/26.
//

import WebKit
import SnapKit

final class KakaoPostCodeViewController: BaseViewController<TempReactor> {
    var webView: WKWebView?
    let indicator = UIActivityIndicatorView(style: .medium) // webView 로딩시 보여줄 뷰
    var onSelectAddress: ((String) -> Void)? // 사용자가 선택한 주소를 전달할 클로저
    
    let contentController = WKUserContentController() // JavaScript가 메세지를 post하고 유저의 스크립트를 webview에 주입할 수 있도록 함
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentController.add(self, name: "callBackHandler")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
        
        guard let url = URL(string: "https://devbambu.github.io/KakaoPostCode/"),
              let webView else { return }
        let request = URLRequest(url: url)
        webView.load(request)
        indicator.startAnimating()
        
        view.addSubview(webView)
        webView.addSubview(indicator)
        
        webView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        indicator.snp.makeConstraints {
            $0.center.equalTo(webView.snp.center)
        }
    }
}

// JavaScript가 보내는 메세지를 수신하기 위한 프로토콜 채택
extension KakaoPostCodeViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        var address = ""
        if let data = message.body as? [String: Any] {
            address = data["roadAddress"] as? String ?? ""
        }
        
        onSelectAddress?(address)
        self.dismiss(animated: true)
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

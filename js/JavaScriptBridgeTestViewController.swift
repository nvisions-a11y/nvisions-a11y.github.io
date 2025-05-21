import UIKit
import WebKit

class JavaScriptBridgeTestViewController: UIViewController {

    // MARK: - Properties

    private var webView: WKWebView!
    // 테스트할 웹 페이지 URL
    private let webViewUrl = "https://khsruru.com/javascript_bridge/#"
    private var isPageLoaded = false
    private var isVoiceOverRunning: Bool = UIAccessibility.isVoiceOverRunning

    // MARK: - Lifecycle Methods

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self // JavaScript Alert 처리 등을 위해 필요
        webView.allowsBackForwardNavigationGestures = true
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "JS Bridge Test (iOS)"

        // VoiceOver 상태 변경 감지 옵저버 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )

        // 초기 URL 로드
        guard let url = URL(string: webViewUrl) else {
            print("Error: Invalid URL - \(webViewUrl)")
            showErrorAlert(message: "유효하지 않은 URL입니다.")
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)

        print("Initial VoiceOver Status (ViewDidLoad): \(isVoiceOverRunning)")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 화면 나타날 때 상태 재전송 (페이지 로드 완료 시)
        sendVoiceOverStatusToWebView()
    }

    deinit {
        // 옵저버 제거
        NotificationCenter.default.removeObserver(
            self,
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
        print("JavaScriptBridgeTestViewController deinitialized and observer removed.")
    }

    // MARK: - VoiceOver Status Handling

    // VoiceOver 상태 변경 시 호출될 메서드
    @objc private func voiceOverStatusChanged() {
        let currentStatus = UIAccessibility.isVoiceOverRunning
        if currentStatus != isVoiceOverRunning {
            isVoiceOverRunning = currentStatus
            print("VoiceOver status changed notification received. New status: \(isVoiceOverRunning)")
            // 변경된 상태 웹뷰로 전송
            sendVoiceOverStatusToWebView()
        }
    }

    // MARK: - JavaScript Bridge Communication

    // VoiceOver 상태를 웹뷰의 JavaScript 함수로 전달
    private func sendVoiceOverStatusToWebView() {
        guard isPageLoaded else {
            // 페이지 로드 전이면 JavaScript 호출 스킵
            print("Page not loaded yet. Skipping sending status.")
            return
        }

        // 웹 페이지의 JavaScript 함수 호출 코드
        let js = """
        if (typeof window.onAccessibilityStatusChanged === 'function') {
            window.onAccessibilityStatusChanged({ voiceOver: \(isVoiceOverRunning), talkBack: false });
            console.log('Sent VoiceOver status to web: \(isVoiceOverRunning)');
        } else {
            console.error('window.onAccessibilityStatusChanged function not found on web page.');
        }
        """
        print("Preparing to evaluate JavaScript: \(js)")

        // 메인 스레드에서 JavaScript 실행
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js) { (result, error) in
                if let error = error {
                    print("Error evaluating JavaScript: \(error.localizedDescription)")
                } else {
                     print("JavaScript evaluation successful.")
                }
            }
        }
    }

    // MARK: - Helper Methods

    // 오류 메시지 Alert 표시
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        DispatchQueue.main.async {
             if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                  var topController = rootVC
                  while let presentedViewController = topController.presentedViewController {
                      topController = presentedViewController
                  }
                  topController.present(alert, animated: true, completion: nil)
             } else {
                  self.present(alert, animated: true, completion: nil)
             }
        }
    }
}

// MARK: - WKNavigationDelegate

extension JavaScriptBridgeTestViewController: WKNavigationDelegate {

    // 페이지 로딩 시작
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Web page loading started: \(webView.url?.absoluteString ?? "unknown URL")")
        isPageLoaded = false
    }

    // 페이지 로딩 완료
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Web page finished loading: \(webView.url?.absoluteString ?? "unknown URL")")
        isPageLoaded = true
        // 페이지 로드 완료 후 초기 상태 전송
        sendVoiceOverStatusToWebView()
    }

    // 페이지 로딩 실패 (메인 프레임)
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Web page failed to load (main navigation): \(error.localizedDescription)")
        isPageLoaded = false
        showErrorAlert(message: "페이지 로드 실패: \(error.localizedDescription)")
    }

    // 페이지 로딩 실패 (프로비저널)
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Web page failed to load (provisional navigation): \(error.localizedDescription)")
        isPageLoaded = false
        showErrorAlert(message: "페이지 로드 오류: \(error.localizedDescription)")
    }

    // 네비게이션 허용 여부 결정
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow) // 기본적으로 허용
    }

    // 응답 수신 후 네비게이션 허용 여부 결정
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow) // 기본적으로 허용
    }
}

// MARK: - WKUIDelegate (JavaScript UI 처리)

extension JavaScriptBridgeTestViewController: WKUIDelegate {
    // JavaScript alert() 처리
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: webView.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            completionHandler()
        }))
        present(alertController, animated: true, completion: nil)
    }

    // JavaScript confirm() 처리
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: webView.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { _ in
            completionHandler(false)
        }))
        present(alertController, animated: true, completion: nil)
    }

    // JavaScript prompt() 처리
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: webView.url?.host, message: prompt, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            completionHandler(alertController.textFields?.first?.text ?? defaultText)
        }))
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { _ in
            completionHandler(nil)
        }))
        present(alertController, animated: true, completion: nil)
    }
}
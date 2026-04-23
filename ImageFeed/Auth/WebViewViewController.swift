internal import UIKit
import WebKit

enum WebViewConstants {
	static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

protocol WebViewViewControllerDelegate: AnyObject {
	func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
	func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}



final class WebViewViewController: UIViewController {
	@IBOutlet weak private var webView: WKWebView!

	@IBOutlet weak private var progressView: UIProgressView!
	weak var delegate: WebViewViewControllerDelegate?
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		webView.navigationDelegate = self
		loadAuthView()
		updateProgress()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: nil)
	}
	
	
	override func observeValue(
		forKeyPath keyPath: String?,
		of object: Any?,
		change: [NSKeyValueChangeKey : Any]?,
		context: UnsafeMutableRawPointer?
	) {
		if keyPath == #keyPath(WKWebView.estimatedProgress) {
			updateProgress()
		} else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	private func updateProgress() {
		progressView.progress = Float(webView.estimatedProgress)
		progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
	}
	
	
	
	private func loadAuthView() {
		guard var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
			return
		}
		
		urlComponents.queryItems = [
			URLQueryItem(name: "client_id", value: Constants.accessKey),
			URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
			URLQueryItem(name: "response_type", value: "code"),
			URLQueryItem(name: "scope", value: Constants.accessScope)
		]
		
		guard let url = urlComponents.url else {
			return
		}
		
		let request = URLRequest(url: url)
		webView.load(request)
	}
}

extension WebViewViewController: WKNavigationDelegate {
	func webView(_ webView: WKWebView,
				 decidePolicyFor navigationAction: WKNavigationAction,
				 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
		if let code = code(from: navigationAction) {
			delegate?.webViewViewController(self, didAuthenticateWithCode: code)
			decisionHandler(.cancel)
		} else {
			decisionHandler(.allow)
		}
	}
	
	private func code(from navigationAction: WKNavigationAction) -> String? {
		if
			let url = navigationAction.request.url,
			let urlComponents = URLComponents(string: url.absoluteString),
			urlComponents.path == "/oauth/authorize/native",
			let items = urlComponents.queryItems,
			let codeItem = items.first(where: { $0.name == "code" })
		{
			print("🔑 Получен код авторизации: \(codeItem.value ?? "nil")")
			return codeItem.value
		} else {
			return nil
		}
	}
	
	func makeAuthTokenRequest(code: String) -> Result<URLRequest, Error>  {
		guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
			return .failure(OAuthError.invalidBaseURL)
		}
		
		urlComponents.queryItems = [
			URLQueryItem(name: "client_id", value: Constants.accessKey),
			URLQueryItem(name: "client_secret", value: Constants.secretKey),
			URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
			URLQueryItem(name: "code", value: code),
			URLQueryItem(name: "grant_type", value: "authorization_code")
		]
		
		guard let authTokenUrl = urlComponents.url else {
			return .failure(OAuthError.invalidBaseURL)
		}
		
		var request = URLRequest(url: authTokenUrl)
		request.httpMethod = "POST"
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		return .success(request)
	}
}









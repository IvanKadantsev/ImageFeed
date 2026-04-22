import UIKit
import WebKit

enum WebViewConstants {
	static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

protocol WebViewViewControllerDelegate: AnyObject {
	func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
	func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}



final class WebViewViewController: UIViewController {
	@IBOutlet private var webView: WKWebView!

	@IBOutlet private var progressView: UIProgressView!
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


enum OAuthError: Error {
	case invalidBaseURL
	case invalidURLComponents
	case networkError(Error)
	case serverError(Int)
	case noData
	case parsingError(Error)
}

struct OAuthTokenResponseBody: Decodable {
	var accessToken: String
	var tokenType: String
	var scope: String
	var createdAt: Int
	
	enum CodingKeys: String, CodingKey {
		case accessToken = "access_token"
		case tokenType = "token_type"
		case scope = "scope"
		case createdAt = "created_at"
	}
}


class OAuth2Service {
	static let shared = OAuth2Service()
	
	private let tokenStorage: OAuth2TokenStorage
	
	private init(tokenStorage: OAuth2TokenStorage = OAuth2TokenStorage()) {
		self.tokenStorage = tokenStorage
	}
	
	func fetchAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
		let webViewController = WebViewViewController()
		
		switch webViewController.makeAuthTokenRequest(code: code) {
		case .success(let request):
			// Используем существующее расширение URLSession.data(for:completion:)
			let task = URLSession.shared.data(for: request) { result in
				switch result {
				case .success(let data):
					// Логирование сырых данных
			if let responseString = String(data: data, encoding: .utf8) {
				print("📦 Ответ сервера (сырые данные): \(responseString)")
			} else {
				print("❌ Не удалось декодировать данные ответа в UTF‑8")
			}
			
			// Декодирование JSON
			do {
				let tokenResponse = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
				
				// Сохранение токена
				self.tokenStorage.token = tokenResponse.accessToken
				
				print("✅ Токен успешно получен и сохранён: \(tokenResponse.accessToken)")
				completion(.success(tokenResponse.accessToken))
			} catch let decodingError {
				let errorMessage = "❌ Ошибка декодирования JSON: \(decodingError.localizedDescription)"
				print(errorMessage)
				completion(.failure(NetworkError.decodingError(decodingError)))
			}
				
				case .failure(let error):
					// Ошибки уже обернуты в NetworkError расширением URLSession
			let errorMessage: String
			switch error {
			case let NetworkError.httpStatusCode(statusCode):
				errorMessage = "❌ Ошибка сервиса Unsplash: HTTP \(statusCode)"
			case let NetworkError.urlRequestError(innerError):
				errorMessage = "❌ Сетевая ошибка: \(innerError.localizedDescription)"
			case NetworkError.urlSessionError:
				errorMessage = "❌ Общая сетевая ошибка сессии"
			default:
				errorMessage = "❌ Неизвестная ошибка: \(error.localizedDescription)"
			}
			print(errorMessage)
			completion(.failure(error))
				}
			}
			task.resume()
		case .failure(let error):
			let errorMessage = "❌ Ошибка формирования запроса: \(error.localizedDescription)"
			print(errorMessage)
			completion(.failure(error))
		}
	}
}

final class OAuth2TokenStorage {
	private let userDefaults: UserDefaults
	private let tokenKey = "oauth2_access_token"
	
	init(userDefaults: UserDefaults = .standard) {
		self.userDefaults = userDefaults
	}
	
	var token: String? {
		get {
			let savedToken = userDefaults.string(forKey: tokenKey)
			if savedToken != nil {
				print("🔐 Токен успешно прочитан из UserDefaults")
			} else {
				print("❌ Токен не найден в UserDefaults")
			}
			return savedToken
		}
		set {
			do {
				if let newToken = newValue {
					userDefaults.set(newToken, forKey: tokenKey)
			print("💾 Токен сохранён в UserDefaults: \(newToken.prefix(10))...")
		} else {
			userDefaults.removeObject(forKey: tokenKey)
			print("🗑️ Токен удалён из UserDefaults")
		}
				try userDefaults.synchronize()
			} catch {
				print("❌ Ошибка сохранения токена в UserDefaults: \(error)")
			}
		}
	}
}


import Foundation
internal import UIKit

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
			let task = URLSession.shared.data(for: request) { result in
				switch result {
				case .success(let data):
					// Логирование сырых данных
			if let responseString = String(data: data, encoding: .utf8) {
				print("📦 Ответ сервера (сырые данные): \(responseString)")
			} else {
				print("❌ Не удалось декодировать данные ответа в UTF‑8")
			}
			
			do {
				let tokenResponse = try JSONDecoder().decode(OAuthTokenResponseBody.self, from: data)
				
				self.tokenStorage.token = tokenResponse.accessToken
				
				print("✅ Токен успешно получен и сохранён: \(tokenResponse.accessToken)")
				completion(.success(tokenResponse.accessToken))
			} catch let decodingError {
				let errorMessage = "❌ Ошибка декодирования JSON: \(decodingError.localizedDescription)"
				print(errorMessage)
				completion(.failure(NetworkError.decodingError(decodingError)))
			}
				
				case .failure(let error):
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

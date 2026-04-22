import UIKit

final class AuthViewController: UIViewController {
	let showWebViewSegueIdentifier = "ShowWebView"
	
	weak var delegate: AuthViewControllerDelegate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		configureBackButton()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == showWebViewSegueIdentifier {
			guard
				let webViewViewController = segue.destination as? WebViewViewController
			else {
				assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
				return
			}
			webViewViewController.delegate = self
		} else {
			super.prepare(for: segue, sender: sender)
		}
	}
	
	private func configureBackButton() {
		navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
		navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain,	target: nil, action: nil)
		navigationItem.backBarButtonItem?.tintColor = UIColor(named: "YP Black")
	}
	
	
}

extension AuthViewController: WebViewViewControllerDelegate {
	func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
		print("🔑 Получен код авторизации: \(code)")
		
		let oauthService = OAuth2Service.shared
		oauthService.fetchAuthToken(code: code) { result in
			switch result {
			case .success(let tokenResponse):
				print("✅ Аутентификация успешна! Токен: \(tokenResponse)")
				self.handleSuccessfulAuthentication(token: tokenResponse)
			case .failure(let error):
				self.handleAuthenticationError(error: error)
			}
		}
	}
	
	func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
		vc.dismiss(animated: true)
		print("❌ Аутентификация отменена пользователем")
	}
	
	private func handleSuccessfulAuthentication(token: String) {
		print("💾 Токен сохранён для дальнейшего использования: \(token.prefix(10))...")
		dismiss(animated: true) {
			print("🗽️ Экран авторизации закрыт после успешной аутентификации")
		}
	}
	
	private func handleAuthenticationError(error: Error) {
		var errorMessage: String
		switch error {
		case let NetworkError.httpStatusCode(statusCode):
			errorMessage = "Ошибка сервера (HTTP \(statusCode)). Попробуйте позже."
		case let NetworkError.urlRequestError(innerError):
			errorMessage = "Сетевая ошибка: \(innerError.localizedDescription)"
		case NetworkError.urlSessionError:
			errorMessage = "Общая сетевая ошибка. Проверьте подключение."
		case let NetworkError.decodingError(decodingError):
			errorMessage = "Ошибка обработки данных: \(decodingError.localizedDescription)"
		default:
			errorMessage = "Неизвестная ошибка: \(error.localizedDescription)"
		}
		print("❌ Ошибка аутентификации: \(errorMessage)")
		let alert = UIAlertController(
			title: "Ошибка аутентификации",
			message: errorMessage,
			preferredStyle: .alert
		)
		alert.addAction(UIAlertAction(title: "ОК", style: .default))
		present(alert, animated: true)
	}
}

internal import UIKit

protocol AuthViewControllerDelegate: AnyObject {
	func didAuthenticate(_ vc: AuthViewController)
}


final class SplashViewController: UIViewController {
	
	private let storage = OAuth2TokenStorage()
	private let showAuthenticationScreenSegueIdentifier = "showAuth"
	private let showTabBarController = "showGallery"
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if storage.token != nil {
			switchToTabBarController()
		} else {
			performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
		}
	}
	
	private func switchToTabBarController() {
		// Получаем экземпляр `window` приложения
		guard let window = UIApplication.shared.windows.first else {
			assertionFailure("Invalid window configuration")
			return
		}
		
		// Создаём экземпляр нужного контроллера из Storyboard с помощью ранее заданного идентификатора
		let tabBarController = UIStoryboard(name: "Main", bundle: .main)
			.instantiateViewController(withIdentifier: "TabBarViewController")
		   
		// Установим в `rootViewController` полученный контроллер
		window.rootViewController = tabBarController
	}
}

extension SplashViewController {
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == showAuthenticationScreenSegueIdentifier {
			guard
				let navigationController = segue.destination as? UINavigationController,
				let viewController = navigationController.viewControllers.first as? AuthViewController
			else {
				assertionFailure("Failed to prepare for \(showAuthenticationScreenSegueIdentifier)")
				return
			}
			viewController.delegate = self
		} else{
			super.prepare(for: segue, sender: sender)
		}
	}
}


extension SplashViewController: AuthViewControllerDelegate {
	

	
	func didAuthenticate(_ vc: AuthViewController) {
		vc.dismiss(animated: true)
		print("переход к галерее")
		switchToTabBarController()

	}
}

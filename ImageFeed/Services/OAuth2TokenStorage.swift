import Foundation

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

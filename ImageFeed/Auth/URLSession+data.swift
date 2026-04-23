import Foundation

enum NetworkError: Error {  // 1
	case httpStatusCode(Int)
	case urlRequestError(Error)
	case urlSessionError
	case invalidRequest
	case decodingError(Error)
}

extension URLSession {
	func data(
		for request: URLRequest,
		completion: @escaping (Result<Data, Error>) -> Void
	) -> URLSessionTask {
		let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in  // 2
			DispatchQueue.main.async {
				completion(result)
			}
		}
		
		let task = dataTask(with: request, completionHandler: { data, response, error in
			if let response = response as? HTTPURLResponse {
				print("Status: \(response.statusCode)")
			}

			if let error = error {
				print("❌ Ошибка запроса: \(error.localizedDescription)")
				fulfillCompletionOnTheMainThread(.failure(NetworkError.urlRequestError(error)))
				return
			}

			guard let data = data, let response = response, let statusCode = (response as? HTTPURLResponse)?.statusCode else {
				print("❌ Общая ошибка сессии URLSession")
				fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError))
				return
			}

			if 200 ..< 300 ~= statusCode {
				print("✅ Успешный ответ (HTTP \(statusCode)): \(data.count) байт данных")
				fulfillCompletionOnTheMainThread(.success(data))
			} else {
				print("❌ HTTP ошибка: статус \(statusCode)")
				fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
			}
		})

		return task
	}
}


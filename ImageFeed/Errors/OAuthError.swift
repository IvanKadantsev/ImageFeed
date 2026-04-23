import Foundation

enum OAuthError: Error {
	case invalidBaseURL
	case invalidURLComponents
	case networkError(Error)
	case serverError(Int)
	case noData
	case parsingError(Error)
}

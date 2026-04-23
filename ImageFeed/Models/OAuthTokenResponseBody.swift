import Foundation

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

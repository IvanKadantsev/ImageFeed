import UIKit

final class ProfileViewController: UIViewController {
	@IBOutlet private var avatarImageView: UIImageView!
	@IBOutlet private var nameLabel: UILabel!
	@IBOutlet private var loginNameLabel: UILabel!
	@IBOutlet var descriptionLabel: UILabel!
	
	@IBOutlet var logoutButton: UIButton!
	
	@IBAction func didTapLogoutButton() {
	}
	
	
}

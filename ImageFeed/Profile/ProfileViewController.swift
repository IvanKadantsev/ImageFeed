import UIKit

final class ProfileViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		let profileImage = UIImage(named: "loginPhoto")
		let imageView = UIImageView(image: profileImage)
		imageView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(imageView)
		imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32).isActive = true
		imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
		imageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
		imageView.heightAnchor.constraint(equalToConstant: 70).isActive = true

		let nameLabel = UILabel()
		nameLabel.text = "Екатерина Новикова"
		nameLabel.textColor = .white
		nameLabel.font = UIFont.boldSystemFont(ofSize: 23.0)
		nameLabel.numberOfLines = 1
		nameLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(nameLabel)

		nameLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
		nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8).isActive = true
		
		let loginLabel = UILabel()
		loginLabel.text = "@ekaterina_nov"
		loginLabel.textColor = UIColor(named: "YP Gray")
		loginLabel.font = UIFont.systemFont(ofSize: 13.0)
		loginLabel.numberOfLines = 1
		loginLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(loginLabel)

		loginLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
		loginLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8).isActive = true
		
		let userGreeting = UILabel()
		userGreeting.text = "Hello, world!"
		userGreeting.textColor = .white
		userGreeting.font = UIFont.systemFont(ofSize: 13.0)
		userGreeting.numberOfLines = 1
		userGreeting.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(userGreeting)

		userGreeting.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
		userGreeting.topAnchor.constraint(equalTo: loginLabel.bottomAnchor, constant: 8).isActive = true
		
		let logoutButton = UIButton.systemButton(
			with: UIImage(systemName: "ipad.and.arrow.forward")!,
			target: self,
			action: #selector(Self.didTapLogoutButton))
		logoutButton.tintColor = UIColor(named: "YP Red")
		logoutButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(logoutButton)
		logoutButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
		logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
		logoutButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
		logoutButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
		
	}
	
	@objc private func didTapLogoutButton() {
		print("Logout")
	}
	
	
}

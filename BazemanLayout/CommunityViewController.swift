//
//  CommunityViewController.swift
//  BazemanLayout
//
//  Created by Charlie Aronson on 6/20/25.
//


//import UIKit
//
//class CommunityViewController: UIViewController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.navigationController?.navigationBar.titleTextAttributes = [
//            .foregroundColor: UIColor.nice2,
//            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
//        ]
//        
//        setupUI()
//    }
//    
//    func setupUI() {
//        view.backgroundColor = .systemBackground
//     
//        // Business stack view
//        let bizStack = UIStackView()
//        bizStack.axis = .vertical
//        bizStack.spacing = 20
//        bizStack.translatesAutoresizingMaskIntoConstraints = false
//
//        // Sample business data
//        let businesses = [
//            ("Joe's Coffee", "A cozy neighborhood coffee shop with a passion for espresso and fresh pastries."),
//            ("GreenLeaf Market", "Your local organic grocer with fresh produce, bulk goods, and eco-friendly products."),
//            ("TechFix", "Fast and affordable phone and computer repairs with excellent customer service.")
//        ]
//        
//        for (name, description) in businesses {
//            bizStack.addArrangedSubview(createBusinessView(name: name, description: description))
//        }
//        
//        // Container stack
//        let mainStack = UIStackView(arrangedSubviews: [bizStack])
//        mainStack.axis = .vertical
//        mainStack.spacing = 30
//        mainStack.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(mainStack)
//        
//        NSLayoutConstraint.activate([
//            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
//        ])
//    }
//    
//    func createBusinessView(name: String, description: String) -> UIView {
//        let container = UIStackView()
//        container.axis = .vertical
//        container.spacing = 8
//
//        let nameLabel = UILabel()
//        nameLabel.text = name
//        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
//
//        let horizontalStack = UIStackView()
//        horizontalStack.axis = .horizontal
//        horizontalStack.spacing = 10
//        horizontalStack.distribution = .fill
//
//        let descLabel = UILabel()
//        descLabel.text = description
//        descLabel.font = UIFont.systemFont(ofSize: 15)
//        descLabel.numberOfLines = 0
//        descLabel.translatesAutoresizingMaskIntoConstraints = false
//
//        let imageView = UIImageView()
//        imageView.image = UIImage(systemName: "photo")
//        imageView.contentMode = .scaleAspectFit
//        imageView.tintColor = .gray
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
//        imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
//
//        horizontalStack.addArrangedSubview(descLabel)
//        horizontalStack.addArrangedSubview(imageView)
//
//        container.addArrangedSubview(nameLabel)
//        container.addArrangedSubview(horizontalStack)
//
//        return container
//    }
//
//}

import UIKit

class CommunityViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // view.backgroundColor = .systemBackground
        // navigationController?.navigationBar.titleTextAttributes = [
        //     .foregroundColor: UIColor.blue,
        //     .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        // ]
        
        // Create and configure label
        let messageLabel = UILabel()
        messageLabel.text = "Community ads coming soon! We'll provide info on local businesses and locations in a coming update."
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        messageLabel.textColor = .secondaryLabel
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
}
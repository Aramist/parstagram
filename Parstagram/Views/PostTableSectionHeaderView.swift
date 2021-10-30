//
//  PostTableSectionHeaderView.swift
//  Parstagram
//
//  Created by Aramis on 10/30/21.
//

import UIKit

class PostTableSectionHeaderView: UITableViewHeaderFooterView {

    var profileImageView: UIImageView?
    var usernameLabel: UILabel?
    
    
    override func updateConfiguration(using state: UIViewConfigurationState) {
        contentView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.image = UIImage(named: "default_profile_image")!
        
        let usernameLabel = UILabel()
        usernameLabel.font = UIFont.systemFont(ofSize: 16)
        usernameLabel.textColor = .white
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Now arrange the subviews:
        contentView.addSubview(profileImageView)
        contentView.addSubview(usernameLabel)
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor),
            usernameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8)
        ])
        profileImageView.layer.cornerRadius = 20
        
        self.profileImageView = profileImageView
        self.usernameLabel = usernameLabel
    }
    
}

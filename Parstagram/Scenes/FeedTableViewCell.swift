//
//  FeedTableViewCell.swift
//  Parstagram
//
//  Created by Aramis on 10/29/21.
//

import UIKit

class FeedTableViewCell: UITableViewCell {

    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var postAuthor: UILabel!
    @IBOutlet weak var postCaption: UILabel!
    @IBOutlet weak var postAge: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)
    }

}

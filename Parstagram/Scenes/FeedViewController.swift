//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Aramis on 10/29/21.
//

import UIKit

import Parse

class FeedViewController: UIViewController {
    
    @IBOutlet weak var feedTableView: UITableView!
    
    var refreshControl: UIRefreshControl?
    
    var posts: [PFObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        feedTableView.delegate = self
        feedTableView.dataSource = self
        feedTableView.separatorStyle = .none
        
        setupRefresh()
        
        feedTableView.register(PostTableSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: "postHeaderView")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        queryPosts()
    }
    
    static func contentAgeString(forCreationDate date: Date?) -> String {
        // If we can't figure out the actual time difference for any reason, return "Just now"
        
        guard let date = date else {return "Just now"}
        // Change sign because date - now < 0
        let timeDiff = -date.timeIntervalSinceNow
        
        switch timeDiff {
        case 0..<60:  // No point in being more specific
            return "Just now"
        case 60..<60*60:  // Between 1m and 1h
            let timeMinutes = Int(timeDiff / 60.0)
            return "\(timeMinutes)m"
        case 60*60..<3600*24:  // 1h to 23h
            let timeHours = Int(timeDiff / 3600.0)
            return "\(timeHours)h"
        case 3600*24..<3600*24*30:  // 1d to 30d
            let timeDays = Int(timeDiff / 3600.0 / 24.0)
            return "\(timeDays)d"
        case 3600*24*30..<3600*24*365:  // 1m to 1y
            let timeMonths = Int(timeDiff / 3600.0 / 24.0 / 30.0)
            return "\(timeMonths)M"
        default:
            let timeYears = Int(timeDiff / 3600.0 / 24.0 / 365.0)
            return "\(timeYears)y"
        }
    }
    
    func setupRefresh() {
        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull down to refresh")
        refreshControl.addTarget(self, action: #selector(queryPosts), for: .valueChanged)
        feedTableView.insertSubview(refreshControl, at: 0)
        self.refreshControl = refreshControl
    }
    
    func asyncDownloadImage(from url: URL, to imageView: UIImageView){
        // Taken from stackoverflow: https://stackoverflow.com/questions/24231680/loading-downloading-image-from-url-on-swift
        let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard error == nil,
                  let data = data else {return}
            // New knowledge, the UI should always be updated from the main thread
            // DispatchQueue.main provides an avenue for doing this:
            DispatchQueue.main.async { [weak imageView] in
                guard let imageView = imageView else {return}
                imageView.image = UIImage(data: data)
            }
        }
        
        task.resume()
    }

    @objc func queryPosts() {
        let query = PFQuery(className: "Post")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 20
        
        query.findObjectsInBackground() { (posts, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                self.posts = posts!
                // By default, the oldest display first. Reverse to put newer posts ahead
                self.posts.reverse()
                self.feedTableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    @IBAction func onLogoutButton(_ sender: Any) {
        let main = UIStoryboard(name: "Main", bundle: nil)
        let vc = main.instantiateViewController(withIdentifier: "loginVC")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = windowScene.delegate as? SceneDelegate else {return}
        PFUser.logOut()
        delegate.window?.rootViewController = vc
    }
    
}

extension FeedViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 50  // Should be enough space for the profile image
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let post = posts[section]
        guard let author = post["author"] as? PFUser,
              let username = author.username,
              let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "postHeaderView") as? PostTableSectionHeaderView
        else {
            print("Broke first guard clause. Section: \(section)")
            return nil
        }
        
        headerView.updateConfiguration(using: headerView.configurationState)
        
        guard let profileImageView = headerView.profileImageView,
              let usernameLabel = headerView.usernameLabel
        else {
            print("Broke second guard block")
            return nil
        }
        
        // This property hasn't necessarily been set for all users
    profileIf: if let userProfileImage = author["profile_image"] as? PFFileObject{
            guard let imageURLString = userProfileImage.url,
                  let profileImageURL = URL(string: imageURLString) else {break profileIf}
        asyncDownloadImage(from: profileImageURL, to: profileImageView)
        }
        usernameLabel.text = username
        print(username)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let row = indexPath.row
        let post = posts[row]
        
        guard let user = PFUser.current() else {return}
        
        let comment = PFObject(className: "Comment")
        comment["author"] = user
        comment["post"] = post
        comment["content"] = "Some comment text"
        
        
//        post.add(comment, forKey: "comments")
//
//        post.saveInBackground { (success, error) in
//            if error != nil {
//                print(error!.localizedDescription)
//            } else {
//                // nice
//            }
//        }
    }
    
}

extension FeedViewController: UITableViewDataSource {
    
    func commentCount(for post: PFObject) -> Int{
        guard let comments = post["comments"] as? [PFObject] else {return 0}
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentCount(for: posts[section]) + 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 { // First row of a soction -> it's a post
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as? FeedTableViewCell else {fatalError()}
            
            // Start by creating a horizontal line separating this post and the previous:
            let divider = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            divider.translatesAutoresizingMaskIntoConstraints = false
            divider.backgroundColor = .gray
            cell.addSubview(divider)
            NSLayoutConstraint.activate([
                divider.topAnchor.constraint(equalTo: cell.topAnchor),
                divider.centerXAnchor.constraint(equalTo: cell.centerXAnchor),
                divider.widthAnchor.constraint(equalTo: cell.widthAnchor, multiplier: 0.9),
                divider.heightAnchor.constraint(equalToConstant: 0.5)
            ])
            
            let idx = indexPath.section
            let post = posts[idx]
            guard let author = post["author"] as? PFUser else {return cell}
            guard let caption = post["caption"] as? String else {return cell}
            guard let username = author.username else {return cell}
            
            cell.postAuthor.text = username
            cell.postCaption.text = caption
            cell.postAge.text = FeedViewController.contentAgeString(forCreationDate: post.createdAt)
            cell.postImage.image = UIImage(named: "image_placeholder")!
            cell.postImage.layer.cornerRadius = 5
            
            // TODO: include a default image asset for images that could not be loaded here
            let imageURLObject = post["image"] as! PFFileObject
            guard let imageURL = URL(string: imageURLObject.url ?? "") else {return cell}
            asyncDownloadImage(from: imageURL, to: cell.postImage)
//            if let imageData = try? Data(contentsOf: imageURL) {
//                cell.postImage.image = UIImage(data: imageData)
//                cell.postImage.layer.cornerRadius = 5
//            }
        
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell") as? CommentTableViewCell else {fatalError()}
            
            let postIdx = indexPath.section
            let commentIdx = indexPath.row - 1
            let post = posts[postIdx]
            
            guard let author = post["author"] as? PFUser else {return cell}
            guard let username = author.username else {return cell}
            guard let comments = post["comments"] as? [PFObject] else {return cell}
            
            let comment = comments[commentIdx]
            
            guard let commentContent = comment["content"] as? String else {return cell}
            
            cell.authorLabel.text = username
            cell.contentLabel.text = commentContent
            
            return cell
        }
    }
}

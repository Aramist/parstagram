//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Aramis on 10/29/21.
//

import UIKit

import MessageInputBar
import Parse


class FeedViewController: UIViewController {
    
    @IBOutlet weak var feedTableView: UITableView!
    
    var refreshControl: UIRefreshControl?
    let commentInputBar = MessageInputBar()
    var showsCommentBar = false
    
    var posts: [PFObject] = []
    
    var activePost: PFObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentInputBar.inputTextView.placeholder = "Add a comment..."
        commentInputBar.sendButton.title = "Post"
        commentInputBar.delegate = self
        // For some reason it was white by default and impossible to see...
        commentInputBar.inputTextView.textColor = .black
        
        feedTableView.delegate = self
        feedTableView.dataSource = self
        feedTableView.separatorStyle = .none
        feedTableView.keyboardDismissMode = .interactive
        
        setupRefresh()
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        queryPosts()
    }
    
    override var inputAccessoryView: UIView? {
        return commentInputBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showsCommentBar
    }
    
    @objc func keyboardWillBeHidden(note: Notification) {
        commentInputBar.inputTextView.text = ""
        showsCommentBar = false
        becomeFirstResponder()
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let postIdx = indexPath.section
        let post = posts[postIdx]
        let commentIdx = indexPath.row
        
        if commentIdx == commentCount(for: post) + 1 {
            activePost = post
            showsCommentBar = true
            becomeFirstResponder()
            commentInputBar.inputTextView.becomeFirstResponder()
        }
    }
    
}

extension FeedViewController: UITableViewDataSource {
    
    func commentCount(for post: PFObject) -> Int{
        guard let comments = post["comments"] as? [PFObject] else {return 0}
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentCount(for: posts[section]) + 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let postIdx = indexPath.section
        let commentIdx = indexPath.row
        let post = posts[postIdx]
        let imageFileObject = post["image"] as? PFFileObject
        let author = post["author"] as? PFUser
        let caption = post["caption"] as? String
        let username = author?.username
        let comments = post["comments"] as? [PFObject]
        let commentCount = commentCount(for: post)
        // Guard statements are left inside the if statements to allow empty cells to be
        // returned if any info is missing
        
        
        if indexPath.row == 0 { // First row of a section -> it's a post
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
            
            guard let caption = caption else {return cell}
            guard let username = username else {return cell}
            
            cell.postAuthor.text = username
            cell.postCaption.text = caption
            cell.postAge.text = FeedViewController.contentAgeString(forCreationDate: post.createdAt)
            cell.postImage.image = UIImage(named: "image_placeholder")!
            cell.postImage.layer.cornerRadius = 5
            
            // TODO: include a default image asset for images that could not be loaded here
            guard let imageFileObject = imageFileObject,
                  let imageURL = URL(string: imageFileObject.url ?? "") else {return cell}
            asyncDownloadImage(from: imageURL, to: cell.postImage)
        
            return cell
        } else if commentIdx < commentCount + 1{
            guard let username = username,
                  let comments = comments,
                  let commentContent = comments[commentIdx - 1]["content"] as? String
            else {return UITableViewCell()}
            
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell") as? CommentTableViewCell else {fatalError()}
            
            cell.authorLabel.text = username
            cell.contentLabel.text = commentContent
            
            return cell
        } else {
            // If this fails there is no recourse anyway
            return tableView.dequeueReusableCell(withIdentifier: "addCommentCell")!
        }
    }
}

extension FeedViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        if let post = activePost {
            let comment = PFObject(className: "Comment")
            comment["author"] = post["author"]
            comment["post"] = post
            comment["content"] = commentInputBar.inputTextView.text
            
            post.add(comment, forKey: "comments")
            // Immediately update comments locally while the network request happens in the background
            feedTableView.reloadData()
            post.saveInBackground()
        }
        
        // Clear the input field (copied from above) and dismiss it
        commentInputBar.inputTextView.text = ""
        showsCommentBar = false
        becomeFirstResponder()
        commentInputBar.inputTextView.resignFirstResponder()
    }
}

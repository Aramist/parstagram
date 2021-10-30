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
    
    var posts: [PFObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        feedTableView.delegate = self
        feedTableView.dataSource = self
        feedTableView.separatorStyle = .none
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        queryPosts()
    }
    
    func queryPosts() {
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
        let row = indexPath.row
        let post = posts[row]
        
        guard let user = PFUser.current() else {return}
        
        let comment = PFObject(className: "Comment")
        comment["author"] = user
        comment["post"] = post
        comment["content"] = "Some comment text"
        
        post.add(comment, forKey: "comments")
        post.saveInBackground { (success, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                // nice
            }
        }
    }
    
    func commentCount(for post: PFObject) -> Int{
        guard let comments = post["comments"] as? [PFObject] else {return 0}
        return comments.count
    }
    
}

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentCount(for: posts[section]) + 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 { // First row of a soction -> it's a post
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as? FeedTableViewCell else {fatalError()}
              
            let idx = indexPath.section
            let post = posts[idx]
            
            guard let author = post["author"] as? PFUser else {return cell}
            guard let caption = post["caption"] as? String else {return cell}
            guard let username = author.username else {return cell}
            
            cell.postAuthor.text = "@\(username)"
            cell.postCaption.text = caption
            
            // TODO: include a default image asset for images that could not be loaded here
            let imageURLObject = post["image"] as! PFFileObject
            guard let imageURL = URL(string: imageURLObject.url ?? "") else {return cell}
            if let imageData = try? Data(contentsOf: imageURL) {
                cell.postImage.image = UIImage(data: imageData)
            }
        
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
            
            cell.authorLabel.text = "@\(username):"
            cell.contentLabel.text = commentContent
            
            return cell
        }
    }
}

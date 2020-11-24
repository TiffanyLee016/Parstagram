//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Tiffany Lee on 11/10/20.
//

import UIKit
import AlamofireImage
import Parse
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
    let commentBar = MessageInputBar()
    
    @IBAction func onLogoutButton(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(identifier: "LoginViewController")
        let sceneDelegate = self.view.window?.windowScene?.delegate as! SceneDelegate
      
        sceneDelegate.window?.rootViewController = loginViewController
        
    }
    @IBOutlet weak var tableView: UITableView!
    
    var posts = [PFObject] ()
    var refreshControl: UIRefreshControl!
    var showsCommentBar = false
    var selectedPost: PFObject!
    
    let myRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .interactive
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "onRefresh", for: UIControl.Event.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
        
       let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillHideNotification(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillHideNotification(note: Notification) {
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showsCommentBar
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let query = PFQuery (className: "Posts")
        query.includeKeys(["author","comments","comments.author"])
        query.limit = 20
        
        query.findObjectsInBackground { (posts,error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
    }
    func onRefresh() {
        run(after: 2) {
               self.refreshControl.endRefreshing()
            }
    }
    // Implement the delay method
    func run(after wait: TimeInterval, closure: @escaping () -> Void) {
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: DispatchTime.now() + wait, execute: closure)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        return comments.count + 2
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
            let comments = (post["comments"] as? [PFObject]) ?? []
            
            if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            
            let user = post["author"] as! PFUser
            cell.usernameLabel.text = user.username
            
            cell.captionLabel.text = post["caption"] as? String

           let imageFile = post["image"] as! PFFileObject
           let urlString = imageFile.url!
           let url = URL(string: urlString)!
            
          cell.photoView.af_setImage(withURL: url)
        
            return cell
            
            } else if indexPath.row <= comments.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
            
            let comment = comments[indexPath.row - 1]
            cell.commentLabel.text = comment["text"] as? String
            
            let user = comment["author"] as! PFUser
            cell.nameLabel.text = user.username
            return cell
           
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentCell")!
                
                return cell
            }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 {
            showsCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            
            selectedPost = post
        }
    }
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let comments = PFObject(className: "Comments")
        
        // Create the comment
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        comment["posts"] = selectedPost
        comment["author"] = PFUser.current()!
   
        selectedPost.add(comment, forKey: "comments")
   
        selectedPost.saveInBackground{ (success, error) in
        if success {
            print("Comment saved")
        } else {
            print("Error saving comment")
        }
    }
        tableView.reloadData()
        // Clear and dismiss the input bar
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        
        commentBar.inputTextView.resignFirstResponder()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


    }

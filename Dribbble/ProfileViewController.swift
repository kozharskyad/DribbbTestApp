//
//  ProfileViewController.swift
//  Dribbble
//
//  Created by Александр Кожарский on 13.10.16.
//  Copyright © 2016 kozharsky. All rights reserved.
//

import UIKit
import SwiftyJSON

class CustomProfCell: UITableViewCell {
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var dtOrLikesnum: UILabel!
    @IBOutlet weak var shotName: UILabel!
}

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static var username: String = ""
    
    var followersClicked: Bool = false
    var likesUrl: String = ""
    var followersUrl: String = ""
    
    var avatars = [String]()
    var shotnames = [String]()
    var dtsOrLikesnum = [String]()
    var usernames = [String]()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userInfoLabel: UILabel!
    @IBOutlet weak var userLikesButton: UIButton!
    @IBOutlet weak var userFollowersButton: UIButton!
    @IBOutlet weak var listLabel: UILabel!
    
    @IBAction func backButtonTap(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func likesButtonTap(_ sender: AnyObject) {
        guard self.followersClicked else { return }
        self.followersClicked = false
        self.listLabel.text = "Likes"
        loadLikes()
    }
    
    @IBAction func followersButtonTap(_ sender: AnyObject) {
        guard !self.followersClicked else { return }
        self.followersClicked = true
        self.listLabel.text = "Followers"
        loadFollowers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadLikes()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DribbApiManager.inst.getUserInfo(username: ProfileViewController.username, completion: { (result) -> Void in
            self.userAvatar.contentMode = .scaleAspectFit
            self.userAvatar.sd_setImage(with: NSURL(string: result?["avatar_url"] as! String) as! URL)
            self.userNameLabel.text = result?["name"] as! String?
            self.userInfoLabel.text = result?["bio"] as! String?
            self.userInfoLabel.text = self.userInfoLabel.text?.stripHTML()
            let likesCount = result!["likes_count"]?.stringValue
            let followersCount = result!["followers_count"]?.stringValue
            let likesButtonTitle: String = (self.userLikesButton.titleLabel?.text)! + likesCount! + " )"
            let followersButtonTitle: String = (self.userFollowersButton.titleLabel?.text)! + followersCount! + " )"
            self.userLikesButton.setTitle(likesButtonTitle, for: .normal)
            self.userFollowersButton.setTitle(followersButtonTitle, for: .normal)
            self.listLabel.text = "Likes"
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.usernames.count
    }
    
    func loadLikes() {
        DribbApiManager.inst.getUserLikes(username: ProfileViewController.username, completion: { (result) -> Void in
            self.avatars.removeAll(keepingCapacity: true)
            self.shotnames.removeAll(keepingCapacity: true)
            self.dtsOrLikesnum.removeAll(keepingCapacity: true)
            self.usernames.removeAll(keepingCapacity: true)
            
            // И тут я раскурил SwiftyJSON и понял, что жизнь с ним намнооого легче,
            // чем с классическими NSDictionary, NSArray и прочим ужасом при работе
            // с сериализованным JSON-Any-респонсом Alamofire
            if let likes = result.array {
                for like in likes {
                    let avatar = like["shot"]["user"]["avatar_url"].string
                    let username = like["shot"]["user"]["name"].string
                    let shotname = like["shot"]["title"].string
                    let dt = like["created_at"].string
                    
                    guard avatar != nil && username != nil && shotname != nil && dt != nil else {
                        print("AVATAR=\(avatar) | USERNAME=\(username) | SHOTNAME=\(shotname) | DT=\(dt)")
                        continue
                    }
                    
                    self.avatars.append(avatar!)
                    self.usernames.append(username!)
                    self.shotnames.append(shotname!)
                    self.dtsOrLikesnum.append(dt!)
                }
                self.tableView.rowHeight = 65
                self.tableView.reloadData()
            }
        })
    }
    
    func loadFollowers() {
        DribbApiManager.inst.getUserFollowers(username: ProfileViewController.username, completion: { (result) -> Void in
            self.avatars.removeAll(keepingCapacity: true)
            self.shotnames.removeAll(keepingCapacity: true)
            self.dtsOrLikesnum.removeAll(keepingCapacity: true)
            self.usernames.removeAll(keepingCapacity: true)
            
            if let followers = result.array {
                for follower in followers {
                    let avatar = follower["follower"]["avatar_url"].string
                    let username = follower["follower"]["name"].string
                    let likesNum = follower["follower"]["likes_count"].stringValue
                    
                    guard avatar != nil && username != nil && likesNum != "" else {
                        print("AVATAR=\(avatar) | USERNAME=\(username) | LIKESNUM=\(likesNum)")
                        continue
                    }
                    
                    self.avatars.append(avatar!)
                    self.usernames.append(username!)
                    self.dtsOrLikesnum.append(likesNum)
                }
                self.tableView.rowHeight = 50
                self.tableView.reloadData()
            }
        })
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CustomProfCell = tableView.dequeueReusableCell(withIdentifier: "ProfCell") as! CustomProfCell
        cell.avatar.sd_setImage(with: NSURL(string: self.avatars[indexPath.row]) as URL!)
        cell.userName.text = self.usernames[indexPath.row]
        let dt = self.followersClicked ? self.dtsOrLikesnum[indexPath.row] : self.dtsOrLikesnum[indexPath.row].dateFormatFromTZ()
        cell.dtOrLikesnum.text = (self.followersClicked ? "Likes count: " : "") + dt
        cell.shotName.text = self.followersClicked ? "" : "Shot: " + self.shotnames[indexPath.row]
        return cell
    }
}

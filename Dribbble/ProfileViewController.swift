//
//  ProfileViewController.swift
//  Dribbble
//
//  Created by Александр Кожарский on 13.10.16.
//  Copyright © 2016 kozharsky. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static var username: String = ""
    
    var followersClicked: Bool = false
    var likesUrl: String = ""
    var followersUrl: String = ""

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
    }
    
    @IBAction func followersButtonTap(_ sender: AnyObject) {
        guard !self.followersClicked else { return }
        self.followersClicked = true
        self.listLabel.text = "Followers"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
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
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "ProfCell")
        return cell
    }
}

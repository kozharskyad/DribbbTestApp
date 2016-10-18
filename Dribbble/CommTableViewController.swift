//
//  CommTableViewController.swift
//  Dribbble
//
//  Created by Александр Кожарский on 11.10.16.
//  Copyright © 2016 kozharsky. All rights reserved.
//

import UIKit
import Foundation
import MBProgressHUD

class Shotcomm {
    var avatar: String?
    var name: String?
    var username: String?
    var dt: String?
    var comm: String?
    
    required init(avatar: String, name: String, username: String, dt: String, comm: String) {
        self.avatar = avatar
        self.name = name
        self.username = username
        self.dt = dt
        self.comm = comm
    }
}

class ShotcommViewModel {
    private var shotcomm: Shotcomm
    
    var avatarUrl: String {
        return shotcomm.avatar!
    }
    
    var nameText: String {
        return (shotcomm.name?.stripHTML())!
    }
    
    var usernameText: String {
        return (shotcomm.username?.stripHTML())!
    }
    
    var timeDate: String {
        return (shotcomm.dt?.dateFormatFromTZ())!
    }
    
    var commentText: String {
        return (shotcomm.comm?.stripHTML())!
    }
    
    required init(shotcomm: Shotcomm) {
        self.shotcomm = shotcomm
    }
}

class CommCustomCell: UITableViewCell {
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var dt: UILabel!
    @IBOutlet weak var comm: UILabel!
}

class CommTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var shotPreview: UIImageView!
    @IBOutlet weak var commentField: UITextField!
    
    static let inst = CommTableViewController()
    
    static var shotId: Int = 0
    static var shotImage: String = ""
    var keyBoardUpped: Bool = false
    
    var shotcomms = [ShotcommViewModel]()
    
    @IBAction func postButtonTap(_ sender: AnyObject) {
        let loadingNotif = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotif.label.text = "Sending comment"
        loadingNotif.hide(animated: true, afterDelay: 5)

        DribbApiManager.inst.sendComment(shotId: CommTableViewController.shotId, text: commentField.text!, completion: { (result) -> Void in
            loadingNotif.hide(animated: true, afterDelay: 0)
            self.loadComments()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        shotPreview.contentMode = .scaleAspectFill
        shotPreview.sd_setImage(with: NSURL(string: CommTableViewController.shotImage) as! URL)
        loadComments()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(CommTableViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CommTableViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        self.tableView.estimatedRowHeight = 86
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    internal func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.shotcomms.count
    }
    
    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CommCustomCell = tableView.dequeueReusableCell(withIdentifier: "CommCell") as! CommCustomCell
        let shotcommModelView = self.shotcomms[indexPath.row]
        
        cell.name.text = shotcommModelView.nameText
        cell.avatar.contentMode = .scaleAspectFill
        cell.avatar.sd_setImage(with: NSURL(string: shotcommModelView.avatarUrl) as! URL)
        cell.comm.text = shotcommModelView.commentText
        cell.comm.sizeToFit()
        cell.dt.text = shotcommModelView.timeDate
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CommTableViewController.cellAction))
        cell.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
        return cell
    }
    
    func cellAction(sender: UITapGestureRecognizer) {
        guard !self.keyBoardUpped else {
            self.view.endEditing(true)
            return
        }
        let tapLoc = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: tapLoc)
        let shotcommViewModel = self.shotcomms[(indexPath?.row)!]
        ProfileViewController.username = shotcommViewModel.usernameText
        performSegue(withIdentifier: "commToProfile", sender: self)
    }
    
    func animateViewMoving(up: Bool, moveValue: CGFloat){
        let movementDuration: TimeInterval = up ? 0.4 : 0.2
        let movement: CGFloat = (up ? -moveValue : moveValue)
        UIView.beginAnimations("animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration )
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
    
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        if let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            animateViewMoving(up: true, moveValue: contentInsets.bottom)
        }
        self.keyBoardUpped = true
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo!
        if let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            animateViewMoving(up: false, moveValue: contentInsets.bottom)
        }
        self.keyBoardUpped = false
    }

    func loadComments() {
        DribbApiManager.inst.getShotComments(shotId: CommTableViewController.shotId, completion: { (result) -> Void in
            if let comments = result.array {
                for comment in comments {
                    let avatar = comment["user"]["avatar_url"].string
                    let name = comment["user"]["name"].string
                    let username = comment["user"]["username"].string
                    let dt = comment["user"]["created_at"].string
                    let comm = comment["body"].string
                    
                    guard avatar != nil &&
                        name != nil &&
                        username != nil &&
                        dt != nil &&
                        comm != nil
                        else { continue }
                    
                    let newComm = Shotcomm(avatar: avatar!, name: name!, username: username!, dt: dt!, comm: comm!)
                    self.shotcomms.append(ShotcommViewModel(shotcomm: newComm))
                    
                    self.tableView.reloadData()
                }
            }
        })
    }
}

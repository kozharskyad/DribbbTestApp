//
//  CommTableViewController.swift
//  Dribbble
//
//  Created by Александр Кожарский on 11.10.16.
//  Copyright © 2016 kozharsky. All rights reserved.
//

import UIKit
import Foundation

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
    
    var avatars = [String]()
    var names = [String]()
    var dts = [String]()
    var comms = [String]()
    var usernames = [String]()
    
    @IBAction func postButtonTap(_ sender: AnyObject) {
        print("POST")
        DribbApiManager.inst.sendComment(shotId: CommTableViewController.shotId, text: commentField.text!, completion: { (result) -> Void in
                print(result)
        })
    }
    
    @IBAction func backButtonTap(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    internal func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return self.comms.count
    }
    
    private func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CommCustomCell = tableView.dequeueReusableCell(withIdentifier: "CommCell") as! CommCustomCell
        cell.name.text = self.names[indexPath.row].stripHTML()
        cell.avatar.contentMode = .scaleAspectFill
        cell.avatar.sd_setImage(with: NSURL(string: self.avatars[indexPath.row]) as! URL)
        cell.comm.text = self.comms[indexPath.row].stripHTML()
        cell.dt.text = self.dts[indexPath.row].stripHTML().dateFormatFromTZ()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CommTableViewController.cellAction))
        cell.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
        return cell
    }
    
    func cellAction(sender: UITapGestureRecognizer) {
        let tapLoc = sender.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: tapLoc)
        ProfileViewController.username = self.usernames[(indexPath?.row)!]
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
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo!
        if let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            animateViewMoving(up: false, moveValue: contentInsets.bottom)
        }
    }

    func loadComments() {
        DribbApiManager.inst.getShotComments(shotId: CommTableViewController.shotId, completion: { (result) -> Void in
            if (result?.count)! > 0 {
                self.names.removeAll(keepingCapacity: false)
                self.avatars.removeAll(keepingCapacity: false)
                self.comms.removeAll(keepingCapacity: false)
                self.dts.removeAll(keepingCapacity: false)

                for commDict in (result as? [[String:Any]])! {
                    if let userDict = commDict["user"] as? NSDictionary {
                        if let avatar = userDict["avatar_url"] {
                            self.avatars.append(avatar as! String)
                        } else {
                            print("NO USER AVATAR")
                        }
                        
                        if let name = userDict["name"] {
                            self.names.append(name as! String)
                        } else {
                            print("NO NAME")
                        }
                        
                        if let username = userDict["username"] {
                            self.usernames.append(username as! String)
                        } else {
                            print("NO USERNAME")
                        }
                        
                        if let dt = userDict["created_at"] {
//                            let dtFormatter = DateFormatter()
//                            dtFormatter.dateFormat = "hh:mm:ss dd.MM.yyyy"
//                            let dateObj = dtFormatter.date(from: dt as! String)
//                            self.dts.append(dtFormatter.string(from: dateObj!))
                            self.dts.append(dt as! String)
                        } else {
                            print("NO USER DT")
                        }
                    } else {
                        print("NO USER DICT")
                    }
                    
                    if let comm = commDict["body"] {
                        self.comms.append(comm as! String)
                    } else {
                        print("NO COMMENT BODY")
                    }
                }
//                print("===========================")
//                print(self.avatars)
//                print(self.names)
//                print(self.dts)
//                print(self.comms)
//                print("===========================")
                self.tableView.reloadData()
            } else {
                print("NO COMMENTS")
            }
        })
    }
}

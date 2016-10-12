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
    
    static let inst = CommTableViewController()
    
    static var shotId: Int = 0
    static var shotImage: String = ""
    
    var avatars = [String]()
    var names = [String]()
    var dts = [String]()
    var comms = [String]()
    
    @IBAction func postButtonTap(_ sender: AnyObject) {
    }
    
    @IBAction func backButtonTap(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        shotPreview.sd_setImage(with: NSURL(string: CommTableViewController.shotImage) as! URL)
        loadComments()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        cell.avatar.sd_setImage(with: NSURL(string: self.avatars[indexPath.row]) as! URL)
        cell.comm.text = self.comms[indexPath.row].stripHTML()
        cell.dt.text = self.dts[indexPath.row].stripHTML()
        return cell
    }
    
    private func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func loadComments() {
        DribbApiManager.inst.getShotComments(shotId: CommTableViewController.shotId, completion: { (result) -> Void in
            if (result?.count)! > 0 {
                self.names.removeAll(keepingCapacity: false)
                self.avatars.removeAll(keepingCapacity: false)
                self.comms.removeAll(keepingCapacity: false)
                self.dts.removeAll(keepingCapacity: false)
//                self.tableView.reloadData()

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
                            print("NO USER NAME")
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
                print("===========================")
                print(self.avatars)
                print(self.names)
                print(self.dts)
                print(self.comms)
                print("===========================")
                self.tableView.reloadData()
            } else {
                print("NO COMMENTS")
            }
        })
    }
}

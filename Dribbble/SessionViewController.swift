//
//  ViewController.swift
//  Dribbble
//
//  Created by Александр Кожарский on 29.09.16.
//  Copyright © 2016 kozharsky. All rights reserved.
//

import UIKit
import RealmSwift
import MBProgressHUD
import SDWebImage

class CustomCell: UITableViewCell {
    @IBOutlet weak var imgPreview: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var desc: UILabel!
}

class SessionViewController: UITableViewController {
    static let inst = SessionViewController()
    
    var runned: Bool = false
    var titles = [String]()
    var descriptions = [String]()
    var images = [String]()
    var shotIds = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl?.addTarget(self, action: #selector(SessionViewController.refresh(panGesture:)), for: UIControlEvents.valueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let realm = try! Realm()
        let objs = realm.objects(LogInfo.self).filter("type = 'access_token'")
        if objs.count > 0 {
            guard runned else {
                performSegue(withIdentifier: "sessionToOAuth", sender: self)
                runned = true
                return
            }
            loadRecentShots()
        } else {
            print("no token. perform login")
            performSegue(withIdentifier: "sessionToLogin", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CustomCell = tableView.dequeueReusableCell(withIdentifier: "LabelCell") as! CustomCell
        cell.title.text = self.titles[indexPath.row]
        cell.desc.text = self.descriptions[indexPath.row]
        cell.imgPreview.sd_setImage(with: NSURL(string: self.images[indexPath.row]) as URL!, completed: nil)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return self.titles.count
        } else {
            return 1
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func loadRecentShots() {
        let loadingNotif = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotif.label.text = "Loading recent shots"
        
        DribbApiManager.inst.getRecentShots()
        DribbApiManager.inst.CompleteLoadShots = {arr -> Void in
            self.titles.removeAll(keepingCapacity: false)
            self.descriptions.removeAll(keepingCapacity: false)
            self.images.removeAll(keepingCapacity: false)
            self.tableView.reloadData()
            
            for shot in (arr as? [[String:Any]])! {
                if let title = shot["title"] as? String {
                    self.titles.append(title.stripHTML())
                } else {
                    self.titles.append("No title")
                }
                
                if let desc = shot["description"] as? String {
                    self.descriptions.append(desc.stripHTML())
                } else {
                    self.descriptions.append("No description")
                }
                
                if let imgUrl = shot["images"] as? NSDictionary {
                    let imgUrlHidpi = imgUrl["hidpi"] as? String
                    let imgUrlNorm = imgUrl["normal"] as? String
                    if imgUrlHidpi == "<null>" || imgUrlHidpi == nil {
                        self.images.append(imgUrlNorm!)
                    } else {
                        self.images.append(imgUrlHidpi!)
                    }
                } else {
                    print("NOIMG")
                }
                
                if let shotId = shot["id"] as? Int {
                    self.shotIds.append(shotId)
                }
//                    DribbApiManager.inst.getShotComments(shotId: shotId, completion: { (result) -> Void in
//                        print("COMMENTS FOR \(shotId):\n\(result)")
//                    })
//                } else {
//                    print("NOCOMM \(shot)")
//                }
            }
            self.tableView.reloadData()
            loadingNotif.hide(animated: true, afterDelay: 0)
            print("titles count \(self.titles.count), desc count \(self.descriptions.count), imgUrl count \(self.images.count)")
//            if (self.refreshControl?.isRefreshing)! {
//                self.refreshControl?.endRefreshing()
//            }
        }
    }
    
    func refresh(panGesture: UIPanGestureRecognizer) {
        self.loadRecentShots()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        CommTableViewController.shotId = self.shotIds[indexPath.row]
        CommTableViewController.shotImage = self.images[indexPath.row]
        performSegue(withIdentifier: "shotToComm", sender: self)
    }
}

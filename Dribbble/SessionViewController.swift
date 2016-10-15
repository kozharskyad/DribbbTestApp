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
import SwiftyJSON

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
    var fromComm: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl?.addTarget(self, action: #selector(SessionViewController.refresh(panGesture:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl!)
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
        cell.imgPreview.contentMode = .scaleAspectFill
//        cell.imgPreview.sd_setImage(with: NSURL(string: self.images[indexPath.row]) as URL!, completed: nil)
        cell.imgPreview.sd_setImageWithPreviousCachedImage(with: NSURL(string: self.images[indexPath.row]) as URL!, placeholderImage: nil, options: SDWebImageOptions.continueInBackground, progress: nil, completed: nil)
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
        // Проверка на переход из вью комментариев. Без неё таблица шотов обновляется при возврате
        guard !self.fromComm else {
            self.fromComm = false
            return
        }
        // **********
        
        let loadingNotif = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotif.label.text = "Loading recent shots"
        
        DribbApiManager.inst.getRecentShots()
        DribbApiManager.inst.CompleteLoadShots = {arr -> Void in
            self.titles.removeAll(keepingCapacity: false)
            self.descriptions.removeAll(keepingCapacity: false)
            self.images.removeAll(keepingCapacity: false)
            self.tableView.reloadData()
            
            if let shots = arr.array {
                for shot in shots {
                    // Проверяем, не анимированный ли шот
                    guard !shot["animated"].bool! else {
                        continue
                    }
                    
                    // Собираем информацию о шоте
                    let title = shot["title"].string
                    let desc = shot["description"].string
                    var imgUrl = shot["images"]["hidpi"].string
                    if imgUrl == nil { imgUrl = shot["images"]["normal"].string }
                    let shotId = shot["id"].int
                    
                    // Проверяем, все ли данные имеются
                    guard title != nil && desc != nil && imgUrl != nil && shotId != nil else { continue }
                    
                    // Пихаем информацию в соответствующие массивы
                    self.titles.append(title!)
                    self.descriptions.append(desc!)
                    self.images.append(imgUrl!)
                    self.shotIds.append(shotId!)
                }
                self.tableView.reloadData()
            }
            loadingNotif.hide(animated: true, afterDelay: 0)
        }
    }
    
    func refresh(panGesture: UIPanGestureRecognizer) {
        self.loadRecentShots()
        self.refreshControl?.endRefreshing()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        CommTableViewController.shotId = self.shotIds[indexPath.row]
        CommTableViewController.shotImage = self.images[indexPath.row]
        self.fromComm = true
        performSegue(withIdentifier: "shotToComm", sender: self)
    }
}

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

class SessionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let inst = SessionViewController()
    @IBOutlet var tableView: UITableView!
    var refreshControl: UIRefreshControl!
    
    var shotList: Results<Shot>!
    
    var runned: Bool = false
    var titles = [String]()
    var descriptions = [String]()
    var images = [String]()
    var shotIds = [Int]()
    var fromComm: Bool = false
    
    @IBAction func logout(_ sender: AnyObject) {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
        performSegue(withIdentifier: "sessionToLogin", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backButt = UIBarButtonItem()
        backButt.title = "Shots"
        navigationItem.backBarButtonItem = backButt
    }
    
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
//            guard runned else {
//                performSegue(withIdentifier: "sessionToOAuth", sender: self)
//                runned = true
//                return
//            }
            loadRecentShots()
        } else {
            print("no token. perform login")
            performSegue(withIdentifier: "sessionToLogin", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CustomCell = tableView.dequeueReusableCell(withIdentifier: "LabelCell") as! CustomCell
        cell.title.text = self.shotList[indexPath.row].title.stripHTML()
        cell.desc.text = self.shotList[indexPath.row].desc.stripHTML()
        cell.imgPreview.contentMode = .scaleAspectFill
        cell.imgPreview.sd_setImageWithPreviousCachedImage(with: NSURL(string: self.shotList[indexPath.row].imgUrl) as URL!, placeholderImage: nil, options: SDWebImageOptions.continueInBackground, progress: nil, completed: nil)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = self.shotList?.count else { return 0 }
        return count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func loadRecentShots() {
        // Проверка на переход из вью комментариев. Без неё таблица шотов обновляется при возврате
        guard !self.fromComm else {
            self.fromComm = false
            return
        }
        
        let loadingNotif = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotif.label.text = "Loading recent shots"
        
        DribbApiManager.inst.getRecentShots()
        let realm = try! Realm()
        DribbApiManager.inst.CompleteLoadShots = {arr -> Void in
            self.titles.removeAll(keepingCapacity: false)
            self.descriptions.removeAll(keepingCapacity: false)
            self.images.removeAll(keepingCapacity: false)
            
            if let shots = arr.array {
                for shot in shots {
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
                    
                    // Записываем шот в реалм
                    let newShot = Shot()
                    newShot.title = title!
                    newShot.desc = desc!
                    newShot.imgUrl = imgUrl!
                    newShot.shotId = shotId!
                    try! realm.write {
                        realm.add(newShot, update: true)
                    }
                    
                }
                self.shotList = realm.objects(Shot.self) // Заполняем переменную результатов для таблицы
                self.tableView.reloadData() // Обновляем таблицу для показа собранных шотов
            }
            loadingNotif.hide(animated: true, afterDelay: 0)
        }
    }
    
    func refresh(panGesture: UIPanGestureRecognizer) {
        self.loadRecentShots()
        self.refreshControl?.endRefreshing()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        CommTableViewController.shotId = self.shotList[indexPath.row].shotId
        CommTableViewController.shotImage = self.shotList[indexPath.row].imgUrl
        self.fromComm = true
        performSegue(withIdentifier: "shotToComm", sender: self)
    }
}

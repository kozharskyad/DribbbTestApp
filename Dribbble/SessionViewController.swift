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
import Realm

class CustomCell: UITableViewCell {
    @IBOutlet weak var imgPreview: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var desc: UILabel!
    @IBOutlet weak var author: UIButton!
    @IBOutlet weak var like: UIButton!
}

// Тут я понял (в самом конце разработки), что такое MVVM и запользовал его,
// но к сожалению только в этом контроллере.
// Однако всецело понял принцип
class Shot: Object {
    dynamic var author: String?
    dynamic var title: String?
    dynamic var desc: String?
    dynamic var imgUrl: String?
    dynamic var shotId: Int = 0
    dynamic var username: String?
    
    required init(author: String, title: String, desc: String, imgUrl: String, shotId: Int, username: String) {
        self.author = author
        self.title = title
        self.desc = desc
        self.imgUrl = imgUrl
        self.shotId = shotId
        self.username = username
        super.init()
    }
    
    required init() {
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }

    override static func primaryKey() -> String? {
        return "shotId"
    }
}

class ShotViewModel {
    var shots: [ShotViewModel] = []
    
    private var shot: Shot
    var authorText: String {
        return shot.author!
    }
    var titleText: String {
        return shot.title!
    }
    var descText: String {
        return shot.desc!
    }
    var imgUrlText: String {
        return shot.imgUrl!
    }
    var shotIdNum: Int {
        return shot.shotId
    }
    var usernameText: String {
        return shot.username!
    }
    
    init(shot: Shot) {
        self.shot = shot
    }
}

class SessionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    static let inst = SessionViewController()
    @IBOutlet var tableView: UITableView!
    var refreshControl: UIRefreshControl!
    
    var shots = [ShotViewModel]()
    
    var fromComm: Bool = false
    
    @IBAction func logout(_ sender: AnyObject) {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
        performSegue(withIdentifier: "sessionToLogin", sender: self)
    }
    
    @IBAction func like(_ sender: AnyObject) {
        let shotsViewModel = shots[sender.tag]
        DribbApiManager.inst.setShotLike(shotId: shotsViewModel.shotIdNum, completion: { (result) -> Void in
            print(result)
        })
    }
    
    @IBAction func authorInfoTap(_ sender: AnyObject) {
        let shotsViewModel = shots[sender.tag]
        ProfileViewController.username = shotsViewModel.usernameText
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
            loadRecentShots()
        } else {
            print("no token. perform login")
            performSegue(withIdentifier: "sessionToLogin", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CustomCell = tableView.dequeueReusableCell(withIdentifier: "LabelCell") as! CustomCell
        let shotsViewModel = self.shots[indexPath.row]
        cell.title.text = shotsViewModel.titleText
        cell.desc.text = shotsViewModel.descText
        cell.imgPreview.contentMode = .scaleAspectFill
        cell.imgPreview.sd_setImageWithPreviousCachedImage(with: NSURL(string: shotsViewModel.imgUrlText) as URL!, placeholderImage: nil, options: SDWebImageOptions.continueInBackground, progress: nil, completed: nil)
        cell.author.setTitle(shotsViewModel.authorText, for: .normal)
        cell.author.tag = indexPath.row
        cell.like.tag = indexPath.row
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shots.count
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
        loadingNotif.hide(animated: true, afterDelay: 5)
        
        DribbApiManager.inst.getRecentShots()
        let realm = try! Realm()
        DribbApiManager.inst.CompleteLoadShots = {arr -> Void in
            if let shots = arr.array {
                for shot in shots {
                    // Игнорируем анимированные шоты
                    guard !shot["animated"].bool! else {
                        continue
                    }
                    
                    // Собираем информацию о шоте
                    let title = shot["title"].string
                    let desc = shot["description"].string
                    var imgUrl = shot["images"]["hidpi"].string
                    if imgUrl == nil { imgUrl = shot["images"]["normal"].string }
                    let shotId = shot["id"].int
                    let author = shot["user"]["name"].string
                    let username = shot["user"]["username"].string
                    
                    // Проверяем, все ли данные имеются
                    guard title != nil && desc != nil && imgUrl != nil && shotId != nil && author != nil else { continue }
                    
                    // Создаём шот
                    let newShot = Shot(author: author!.stripHTML(),
                                       title: title!.stripHTML(),
                                       desc: desc!.stripHTML(),
                                       imgUrl: imgUrl!,
                                       shotId: shotId!,
                                       username: username!.stripHTML()
                    )

                    // Записываем шот в реалм
                    try! realm.write {
                        realm.add(newShot, update: true)
                    }
                    
                }
                // Достаём все записанные ранее шоты из реалма (да, знаю, что можно было элегантнее)
                let realmShots = realm.objects(Shot.self).sorted(byProperty: "shotId", ascending: false)
                self.shots.removeAll(keepingCapacity: false) // Зачищаем массив моделей шотвью
                
                // И пихаем в него шоты, которые достали ранее из реалма
                for realmShot in realmShots {
                    self.shots.append(ShotViewModel(shot: realmShot))
                }
                
                if self.refreshControl.isRefreshing { self.refreshControl.endRefreshing() }
                self.tableView.reloadData() // Обновляем таблицу для показа собранных шотов
            }
            loadingNotif.hide(animated: true, afterDelay: 0)
        }
    }
    
    func refresh(panGesture: UIPanGestureRecognizer) {
        self.loadRecentShots()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let shotsViewModel = self.shots[indexPath.row]
        CommTableViewController.shotId = shotsViewModel.shotIdNum
        CommTableViewController.shotImage = shotsViewModel.imgUrlText
        self.fromComm = true
        performSegue(withIdentifier: "shotToComm", sender: self)
    }
}

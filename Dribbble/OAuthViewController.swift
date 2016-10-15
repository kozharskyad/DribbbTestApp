//
//  LoginPageViewController.swift
//  Dribbble
//
//  Created by Александр Кожарский on 30.09.16.
//  Copyright © 2016 kozharsky. All rights reserved.
//

import UIKit
import RealmSwift
import MBProgressHUD

class OAuthViewController: UIViewController {
    
    static let inst = OAuthViewController()
    var OAuthViewCompleteHandler:(() -> Void)?
    
    @IBAction func unwindOAuth(segue: UIStoryboardSegue?) {
        let tmpController :UIViewController! = self.presentingViewController;
        self.dismiss(animated: false, completion: {()->Void in
            print("done")
            tmpController.dismiss(animated: false, completion: nil)
        });
    }
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loadingNotif = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotif.label.text = "Authenticating..."
        loadingNotif.hide(animated: true, afterDelay: 5)
        
        // Вызов WebView для отображения стандартной формы OAuth2-авторизации
        let reqURL = NSURL(string: "https://dribbble.com/oauth/authorize?client_id=48a0f2d306113b97824df1b199253c2e622263ca9f5a20d8df8b7f47c9ed236b&scope=public%20write")
        let req = NSURLRequest(url: reqURL! as URL)
        webView.loadRequest(req as URLRequest)
        DribbApiManager.inst.OAuthTokenCompletionHandler = {(error) -> Void in
            let presentingViewController = self.presentingViewController
            loadingNotif.hide(animated: true, afterDelay: 0)
            self.dismiss(animated: true, completion: {
                presentingViewController!.dismiss(animated: true, completion: {
//                    DribbApiManager.inst.getUserInfo(usermame: "")
                })
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func dismissOAuth() {
        print("Dismissing OAuth")
    }
}

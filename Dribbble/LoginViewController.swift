//
//  LoginViewController.swift
//  Dribbble
//
//  Created by Александр Кожарский on 29.09.16.
//  Copyright © 2016 kozharsky. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    static let inst = LoginViewController()
    
    @IBAction func logIn(_ sender: AnyObject) {
        performSegue(withIdentifier: "loginToOAuth", sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

//
//  MainNavigationController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 11/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import Foundation
import UIKit

class MainNavigationController: UINavigationController {

    override func viewDidLoad() {
        AppController.navigationController = self
        
        var id :String! = nil
        
        if(AppController.hasJacket())
        {
             id = String(describing: DashBoardViewController.self)
        }else if(AppController.hasJackets()){
            id = String(describing: SettingsViewController.self)
        }else{
            id = String(describing: TutorialViewController.self)
        }
        
        pushViewController(AppController.instantiate(id: id), animated: false)
        setNavigationBarHidden(true, animated: false)
    }
    
}

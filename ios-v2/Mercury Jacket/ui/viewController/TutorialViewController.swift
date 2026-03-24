//
//  TutorialViewController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 11/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit

class TutorialViewController: BaseViewController {

    @IBOutlet weak var close_bt: UIButton!
    
    public var hasBack :Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        close_bt.isHidden = !hasBack
    }
    
    @IBAction func closeHandler(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

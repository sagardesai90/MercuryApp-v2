//
//  Tutorial5ViewController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 11/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit

class Tutorial5ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func start_mercury_handle(_ sender: Any) {
        let v = AppController.instantiate(id: String(describing: NewJacketViewController.self))
        v.modalPresentationStyle = .overCurrentContext
        present(v, animated: true, completion: nil);
    }

}

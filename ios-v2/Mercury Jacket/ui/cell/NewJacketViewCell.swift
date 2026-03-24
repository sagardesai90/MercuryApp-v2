//
//  NewJacketViewCell.swift
//  Mercury Jacket
//
//  Created by André Ponce on 12/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit

class NewJacketViewCell: UITableViewCell {

    @IBOutlet weak var new_bt: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    @IBAction func new_handle(_ sender: Any) {
        let v = AppController.instantiate(id: String(describing: NewJacketViewController.self))
        v.modalPresentationStyle = .overCurrentContext
        AppController.getContext().present(v, animated: true, completion: nil);
    }
}

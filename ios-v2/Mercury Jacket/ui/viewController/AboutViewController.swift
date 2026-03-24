//
//  AboutViewController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 11/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit

class AboutViewController: BaseViewController {

    public var TAG :String = "AboutViewController"
    
    private var bluetoothController :BluetoothController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bluetoothController = BluetoothController.getInstance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_DEVICE_DISCONNECTED) {
            self.close_handle(self);
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.bluetoothController.removeListeners(id: TAG, eventNameToRemoveOrNil: nil)
    }

    @IBAction func close_handle(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

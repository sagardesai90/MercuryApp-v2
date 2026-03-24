//
//  StandByViewController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 11/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit

class StandByViewController: BaseViewController {

    public var TAG :String = "StandByViewController"
    
    private var bluetoothController :BluetoothController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bluetoothController = BluetoothController.getInstance()
    }
    @IBAction func smart_mode_handle(_ sender: Any) {
        self.bluetoothController.writeCharacteristic(uuid: JacketGattAttributes.MODE,value: JacketGattAttributes.SMART_MODE);
        self.bluetoothController.writeCharacteristic(uuid: JacketGattAttributes.MODE,value: JacketGattAttributes.SMART_MODE);
        self.bluetoothController.readCharacteristics()
        ConnectedViewController.instance.setMode(mode: JacketGattAttributes.SMART_MODE)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.bluetoothController.removeListeners(id: TAG, eventNameToRemoveOrNil: nil)
    }
    
}

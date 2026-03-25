//
//  NewJacketViewController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 11/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit
import SwiftyGif
import CoreBluetooth

class NewJacketViewController: UIViewController, UITextFieldDelegate {
    
    public static let ADDED_MSG :String = "Hooray! Your Jacket was successfully added. Start browsing it now."
    public static let NOT_FOUND :String = "The Jacket Could not be found. Make sure the device is ON and charged."
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var searchContainer: UIView!
    @IBOutlet weak var nameContainer: UIView!
    @IBOutlet weak var jacket_image: UIImageView!
    @IBOutlet weak var loader_image: UIImageView!
    @IBOutlet weak var name_txt: UITextField!
    @IBOutlet weak var status_txt: UILabel!
    
    private let TAG :String = "NewJacketViewController"
    
    let timeClose = 2.0;
    let timeToStartScan = 1.5;
    
    var handlerStart :Timer?
    var handlerFound :Timer?
    var device :CBPeripheral?
    
    private var bluetoothController :BluetoothController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameContainer.isHidden = true
        self.name_txt.delegate = self
        
        self.loader_image.setGifImage(UIImage(gifName: "loader.gif"))
        self.loader_image.startAnimatingGif()
        
        self.handlerStart = Timer.scheduledTimer(withTimeInterval: self.timeToStartScan, repeats: false) { timer in
            self.bluetoothController.scanDevice();
            //self.found(device: nil)
        }
        
        self.bluetoothController = BluetoothController.getInstance()
        
        self.bluetoothController.listenTo(id:TAG, eventName: BluetoothController.Events.ON_ADAPTER_DISCONNECT) {
            self.close_handle(self)
        }
        self.bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_SCAN_FOUND) { (param) in
            self.found(device: param as? CBPeripheral)
        }
        self.bluetoothController.listenTo(id:TAG, eventName: BluetoothController.Events.ON_SCAN_NOT_FOUND) {
            self.loader_image.stopAnimatingGif()
            self.loader_image.showFrameAtIndex(0)
            
            let alert :Alert = Alert(context: self)
            alert.yesMessage = "Try Again"
            alert.noMessage = "Cancel"
            alert.create(message: NewJacketViewController.NOT_FOUND, type: Alert.ASK)
            alert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
                if(action==Alert.YES_ACTION){
                    self.loader_image.startAnimatingGif();
                    self.bluetoothController.scanDevice();
                }else{
                    self.close_handle(self)
                }
            }))
            alert.show()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //self.container.roundCorners([.topLeft, .topRight], radius: 15)
    }
    
    func found(device :CBPeripheral!)
    {
        self.device = device;
        
        self.loader_image.stopAnimatingGif();
        self.loader_image.currentImage = UIImage(named: "loaded_bar")
        self.loader_image.tintColor = UIColor(hexString: "#FA7272")
        self.jacket_image.image = UIImage(named: "jacket_found")
        self.status_txt.textColor = #colorLiteral(red: 0.9384049773, green: 0.4642089605, blue: 0.4783027768, alpha: 1);
        self.status_txt.text = "Found!"
        
        self.handlerFound = Timer.scheduledTimer(withTimeInterval: self.timeClose, repeats: false) { timer in
            self.openNameConsole();
        }
    }
    
    func openNameConsole()
    {
        self.searchContainer.isHidden = true
        self.nameContainer.isHidden = false
        self.name_txt.becomeFirstResponder();
    }

    @IBAction func close_handle(_ sender: Any) {
        self.bluetoothController.removeListeners(id: TAG, eventNameToRemoveOrNil: nil)
        if(self.handlerStart != nil)
        {
            self.handlerStart?.invalidate()
            self.handlerStart = nil;
        }
        if(self.handlerFound != nil)
        {
            self.handlerFound?.invalidate()
            self.handlerFound = nil;
        }
        
        self.bluetoothController.stopScan();
        //self.bluetoothController.removeScanListener(listener: self.scanListener)
        dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if(self.name_txt.text == "")
        {
            _ = Alert.show(context: self, message: "Enter a name for the jacket.")
        }else if((self.name_txt.text?.count)!>20)
        {
            _ = Alert.show(context: self, message: "Max characters 20.")
        }else{
            self.save();
            return true;
        }
        return false
    }
    
    func save()
    {
        self.name_txt.resignFirstResponder();
        
        let id   :String = self.device!.identifier.uuidString
        //let id   :String = String(describing: Int.random(in: 0..<6));
        let name :String = name_txt.text!
        let advertised = self.device?.name

        let instance = Jacket(id: id, name: name, advertisedDeviceName: advertised)
        instance.save();
        AppController.connectedTo(jacket: instance);
        
        close_handle(self)
        
        let alert = Alert(context: AppController.getContext())
        alert.create(message: NewJacketViewController.ADDED_MSG, type: Alert.CONFIRM)
        alert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
            AppController.startViewController(viewController: AppController.instantiate(id: String(describing: DashBoardViewController.self)), clearStack: true)
        }))
        alert.show()
    }
}

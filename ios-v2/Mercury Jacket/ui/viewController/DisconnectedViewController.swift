//
//  DisconnectedViewController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 11/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit

class DisconnectedViewController: BaseViewController {

    @IBOutlet weak var loader_image: UIImageView!
    @IBOutlet weak var jacket_image: UIImageView!
    @IBOutlet weak var status_txt: UILabel!
    @IBOutlet weak var connect_bt: UIButton!
    
    public var TAG :String = "DisconnectedViewController"
    
    private var jacket :Jacket!
    private var bluetoothController :BluetoothController!
    private var searching :Bool = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loader_image.setGifImage(UIImage(gifName: "loader_black.gif"))
        self.loader_image.currentImage = UIImage(named: "loaded_bar")
        self.loader_image.tintColor = UIColor(hexString: "#23282E")
        
        self.jacket              = AppController.getCurrentJacket()
        self.bluetoothController = BluetoothController.getInstance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_ADAPTER_CONNECT) {
            self.startSearch();
        }
        self.bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_ADAPTER_DISCONNECT) {
            self.stopSearch();
        }
        self.bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_DEVICE_CONNECTED) { (param) in
            guard let deviceID = param as? String, deviceID == self.jacket.id else { return }
            self.found()
        }
        self.bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_SCAN_NOT_FOUND) {
            self.notFound()
        }
        self.bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_DEVICE_DISCONNECTED) { (params) in
            guard let arr = params as? [AnyObject], let deviceID = arr[0] as? String,
                  deviceID == self.jacket.id else { return }
            if arr[1] as! Bool {
                self.stopSearch()
                self.startSearch()
            } else {
                self.notFound()
            }
        }
        
        if(self.bluetoothController.adapterIsEnabled)
        {
            startSearch();
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("NotConnect REMOVED");
        self.stopSearch();
        self.bluetoothController.removeListeners(id: TAG, eventNameToRemoveOrNil: nil)
    }
    
    func startSearch()
    {
        if(!searching)
        {
            searching = true;
            
            status_txt.text = String(format: "Connecting to %@…", self.jacket.name)
            status_txt.textColor = UIColor.white
            
            loader_image.startAnimatingGif()
            self.jacket_image.image = UIImage(named: "jacket")
            
            connect_bt.isUserInteractionEnabled = false
            connect_bt.alpha = 0.35
            
            self.bluetoothController.connectAllRegistered();
        }
    }
    
    private func stopSearch()
    {
        // Do NOT call bluetoothController.stopScan() here — that would kill any active
        // scan for a different registered device that hasn't connected yet.
        // BluetoothController manages its own scan lifecycle.
        
        searching = false;
        status_txt.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1);
        status_txt.text = String(format: "%@ is Not Connected", self.jacket.name)
        
        self.loader_image.stopAnimatingGif()
        self.loader_image.currentImage = UIImage(named: "loaded_bar")
        self.loader_image.tintColor = UIColor(hexString: "#23282E")
        self.jacket_image.image = UIImage(named: "jacket")
        
        connect_bt.isUserInteractionEnabled = true
        connect_bt.alpha = 1.0
    }
    
    private func found()
    {
        if(searching){
            self.loader_image.stopAnimatingGif();
            self.loader_image.currentImage = UIImage(named: "loaded_bar")
            self.loader_image.tintColor = UIColor(hexString: "#FA7272")
            self.jacket_image.image = UIImage(named: "jacket_found")
            self.status_txt.textColor = #colorLiteral(red: 0.9384049773, green: 0.4642089605, blue: 0.4783027768, alpha: 1);
            self.status_txt.text = "Connected!"
        }
    }
    
    private func notFound()
    {
        stopSearch();
        let alert :Alert = Alert(context: self)
        alert.yesMessage = "Reconnect"
        alert.noMessage = "Cancel"
        alert.create(message: String(format:"The \"%@\" Jacket appears to be out of range or has lost connection, please move your device closer to reconnect.",jacket.name), type: Alert.ASK)
        alert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
            if(action==Alert.YES_ACTION){
                self.startSearch();
            }
        }))
        alert.show()
    }

    @IBAction func connect_handle(_ sender: Any) {
        startSearch();
    }
}

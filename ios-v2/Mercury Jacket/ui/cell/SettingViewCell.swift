//
//  SettingViewCell.swift
//  Mercury Jacket
//
//  Created by André Ponce on 12/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit

class SettingViewCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var header: UIView!
    @IBOutlet weak var name_txt: UILabel!
    @IBOutlet weak var table_view: UITableView!
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var tableHeight: NSLayoutConstraint!
    @IBOutlet weak var arrow_image: UIImageView!
    @IBOutlet weak var connect_bt: RoundedButton!
    @IBOutlet weak var disconenct_bt: RoundedButton!
    @IBOutlet weak var delete_bt: RoundedButton!
    
    private var bluetoothController :BluetoothController!
    var jacket :Jacket? = nil
    private var settings :[[Any]] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.bluetoothController = BluetoothController.getInstance()
        
        table_view.delegate = self
        table_view.dataSource = self
    }
    
    @IBAction func connect_handle(_ sender: Any) {
        let alert = Alert(context: AppController.getContext())
        alert.yesMessage = "Connect"
        alert.noMessage = "Cancel"
        alert.create(message: "Would you like to switch to the \"\(self.jacket!.name)\" jacket?", type: Alert.ASK)
        alert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
            if action == Alert.YES_ACTION {
                // Just switch the selected jacket — all devices stay connected in the background
                AppController.connectedTo(jacket: self.jacket)
                AppController.startViewController(viewController: AppController.instantiate(id: String(describing: DashBoardViewController.self)))
            }
        }))
        alert.show()
    }

    @IBAction func disconnect_handle(_ sender: Any) {
        let alert: Alert = Alert(context: AppController.getContext())
        alert.yesMessage = "Disconnect"
        alert.noMessage = "Cancel"
        alert.create(message: "Are you sure you want to disconnect \"\(self.jacket!.name)\"?", type: Alert.ASK)
        alert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
            if action == Alert.YES_ACTION {
                // Disconnect only this specific device, leave others connected
                if let jacketID = self.jacket?.id {
                    BluetoothController.getInstance().stopConnection(deviceID: jacketID)
                }
                if AppController.getCurrentJacket()?.id == self.jacket?.id {
                    AppController.connectedTo(jacket: nil)
                }
                self.connect_bt.isHidden = false
                self.disconenct_bt.isHidden = true
                SettingsViewController.instance.updateData()

                if AppController.getCurrentJacket() == nil && DashBoardViewController.instance != nil {
                    AppController.removeViewControllerFromStack(view: DashBoardViewController.instance)
                }

                let alert = Alert(context: AppController.getContext())
                alert.confirmMessage = "Continue"
                alert.create(message: String(format: "The Jacket \"%@\" was disconnected.", self.jacket!.name), type: Alert.CONFIRM)
                alert.show()
            }
        }))
        alert.show()
    }

    @IBAction func delete_handle(_ sender: Any) {
        // First confirmation — generic warning
        let alert1: Alert = Alert(context: AppController.getContext())
        alert1.yesMessage = "Continue"
        alert1.noMessage = "Cancel"
        alert1.create(message: "Deleting \"\(self.jacket!.name)\" will remove it from this app and cannot be undone. Are you sure?", type: Alert.ASK)
        alert1.setActionListener(listener: Alert.ActionListener(onActionClick: { (action1) in
            guard action1 == Alert.YES_ACTION else { return }
            // Second confirmation — must explicitly type-confirm intent
            let alert: Alert = Alert(context: AppController.getContext())
            alert.yesMessage = "Yes, Delete"
            alert.noMessage = "Cancel"
            alert.create(message: "This is your final confirmation. \"\(self.jacket!.name)\" will be permanently deleted.", type: Alert.ASK)
            alert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
                if action == Alert.YES_ACTION {
                    // Disconnect only this device before removing it from the registry
                    if let jacketID = self.jacket?.id {
                        BluetoothController.getInstance().stopConnection(deviceID: jacketID)
                    }
                    self.jacket?.delete()
                    SettingsViewController.instance.updateData()

                    if AppController.getCurrentJacket() == nil && DashBoardViewController.instance != nil {
                        AppController.removeViewControllerFromStack(view: DashBoardViewController.instance)
                    }

                    let confirmation = Alert(context: AppController.getContext())
                    confirmation.confirmMessage = "Continue"
                    confirmation.create(message: String(format: "The Jacket \"%@\" was deleted.", self.jacket!.name), type: Alert.CONFIRM)
                    confirmation.setActionListener(listener: Alert.ActionListener(onActionClick: { _ in
                        if !AppController.hasJackets() {
                            AppController.startViewController(viewController: AppController.instantiate(id: String(describing: TutorialViewController.self)), clearStack: true)
                        }
                    }))
                    confirmation.show()
                }
            }))
            alert.show()
        }))
        alert1.show()
    }

    func setJacket(jacket: Jacket)
    {
        self.name_txt.text = jacket.name
        self.connect_bt.title_txt.text = String(format: "Connect %@", jacket.name)
        self.disconenct_bt.title_txt.text = String(format: "Disconnect %@", jacket.name)
        self.delete_bt.title_txt.text = String(format: "Delete %@", jacket.name)
        
        self.connect_bt.isHidden = AppController.getCurrentJacket() != nil ? jacket.id==AppController.getCurrentJacket()?.id : false
        self.disconenct_bt.isHidden = true//AppController.getCurrentJacket() != nil ? jacket.id != AppController.getCurrentJacket()?.id : true
        
        if(AppController.getCurrentJacket() != nil && jacket.id==AppController.getCurrentJacket()?.id){
            self.header.backgroundColor = UIColor(hexString: "#4D565E")
        }else {
            self.header.backgroundColor = UIColor.clear
        }
        
        //if(self.jacket == nil)
        //{
            self.jacket = jacket
            self.settings.removeAll()
            let settings = jacket.getSettings()
            let sorted = settings.sorted(by: {$0.0 > $1.0})
            for data in sorted{
                self.settings.append([data.key,data.value])
            }
            tableHeight.constant = CGFloat(self.settings.count*60)
            table_view.layoutIfNeeded()
            self.table_view.reloadData()
        //}
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config :[Any] = self.settings[indexPath.row]
        let cell :SettingLineViewCell = self.table_view.dequeueReusableCell(withIdentifier: "line") as! SettingLineViewCell
        cell.setConfig(jacket: jacket!, key: config[0] as! Int, value: config[1] as! Bool);
        return cell
    }

    public func expand()
    {
        arrow_image.image = UIImage(named: "seta_baixo")
    }
    
    public func retract()
    {
        arrow_image.image = UIImage(named: "seta_cima")
    }
    
}

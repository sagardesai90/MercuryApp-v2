//
//  SettingsViewController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 12/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit

class SettingsViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    public static var instance :SettingsViewController!
    
    @IBOutlet weak var tableView: UITableView!
    
    var connectedIndexPath: IndexPath? = nil
    var selectedIndexPath: IndexPath? = nil
    var cellHeight :Float = 0
    private var data :[Any] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SettingsViewController.instance = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        updateData()
    }
    
    func updateData()
    {
        data = []
        connectedIndexPath = nil
        selectedIndexPath = nil
        cellHeight = 0
        let jackets = AppController.getJacketsList()
        for jacket in jackets{
            data.append(jacket)
        }
        data.append("temperatureUnit")
        data.append("new")
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if(connectedIndexPath != nil && selectedIndexPath != connectedIndexPath)
        {
            self.tableView.selectRow(at: self.connectedIndexPath, animated: true, scrollPosition: UITableView.ScrollPosition.middle);
            self.tableView?.delegate?.tableView?(self.tableView!, didSelectRowAt: self.connectedIndexPath!)
            connectedIndexPath = nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let element = self.data[indexPath.row]
        var cell :UITableViewCell! = nil
        if let str = element as? String, str == "temperatureUnit" {
            let tCell = tableView.dequeueReusableCell(withIdentifier: "temperatureUnit")
                ?? UITableViewCell(style: .subtitle, reuseIdentifier: "temperatureUnit")
            tCell.textLabel?.text = "Temperature units"
            tCell.detailTextLabel?.text = "Dashboard, stats & Live Activity"
            tCell.detailTextLabel?.textColor = .secondaryLabel
            tCell.selectionStyle = .none
            let seg: UISegmentedControl
            if let existing = tCell.accessoryView as? UISegmentedControl {
                seg = existing
            } else {
                seg = UISegmentedControl(items: ["°C", "°F"])
                seg.addTarget(self, action: #selector(temperatureUnitChanged(_:)), for: .valueChanged)
                tCell.accessoryView = seg
            }
            seg.selectedSegmentIndex = AppController.getTemperatureMeasure() == AppController.FAHRENHEIT ? 1 : 0
            return tCell
        }
        if(element is String)
        {
            cell = self.tableView.dequeueReusableCell(withIdentifier: "new")
        }else{
            let settingCell :SettingViewCell = self.tableView.dequeueReusableCell(withIdentifier: "jacket") as! SettingViewCell
            settingCell.setJacket(jacket: self.data[indexPath.row] as! Jacket)
            if(AppController.getCurrentJacket() != nil && settingCell.jacket!.id==AppController.getCurrentJacket()!.id)
            {
                self.connectedIndexPath = indexPath
            }
            cell = settingCell
            
            if(selectedIndexPath==indexPath)
            {
                settingCell.retract()
            }else{
                settingCell.expand()
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        
        if(cell is NewJacketViewCell)
        {
            return
        }
        guard let settingCell = cell as? SettingViewCell else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        // Inner table + action buttons (connect / disconnect / delete / rename)
        self.cellHeight = Float(settingCell.tableHeight.constant + 280)
        
        switch selectedIndexPath {
        case nil:
            selectedIndexPath = indexPath
        default:
            if selectedIndexPath! == indexPath {
                selectedIndexPath = nil
            } else {
                selectedIndexPath = indexPath
            }
        }
        tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < data.count, data[indexPath.row] as? String == "temperatureUnit" {
            return 72.0
        }
        let cell = tableView.cellForRow(at: indexPath)
        
        let smallHeight: CGFloat = 60.0
        let expandedHeight: CGFloat = CGFloat(self.cellHeight)
        
        var height = CGFloat(0.0)
        
        if selectedIndexPath != nil {
            if indexPath == selectedIndexPath! {
                height = expandedHeight
            } else {
                height = smallHeight
            }
        } else {
            height = smallHeight
        }
        
        if(cell is SettingViewCell)
        {
            let settingCell :SettingViewCell = cell as! SettingViewCell
            
            if(height==smallHeight)
            {
                settingCell.expand()
            }else if(height==expandedHeight){
                settingCell.retract()
            }
        }
        
        return height
    }
    
    @IBAction func close_handle(_ sender: Any) {
        if(AppController.getCurrentJacket() == nil){
            let alert = Alert(context: AppController.getContext())
            alert.create(message: "Are you sure you want to exit application?", type: Alert.ASK)
            alert.setActionListener(listener: Alert.ActionListener(onActionClick: { (action) in
                if(action==Alert.CONFIRM_ACTION)
                {
                    exit(0);
                }
            }))
            alert.show()
        }else{
            self.navigationController?.popViewController(animated: true)
            //AppController.startViewController(viewController: DashBoardViewController.instance != nil ? DashBoardViewController.instance : AppController.instantiate(id: String(describing: DashBoardViewController.self)), clearStack: true)
        }
    }
    
    @IBAction func introHandler(_ sender: Any) {
        let intro : TutorialViewController = AppController.instantiate(id: String(describing: TutorialViewController.self)) as! TutorialViewController;
        intro.hasBack = true
        AppController.startViewController(viewController: intro)
    }

    @objc private func temperatureUnitChanged(_ sender: UISegmentedControl) {
        let useFahrenheit = sender.selectedSegmentIndex == 1
        AppController.setTemperatureMeasure(value: useFahrenheit ? AppController.FAHRENHEIT : AppController.CELSIUS)
        NotificationCenter.default.post(name: .mercuryTemperatureUnitDidChange, object: nil)
        if #available(iOS 16.2, *) {
            Task { await HeatLiveActivityManager.shared.refreshFromBluetoothState() }
        }
    }
}

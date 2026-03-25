//
//  ConnectedViewController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 12/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit
import CoreBluetooth

class ConnectedViewController: BaseViewController {

    public var TAG :String = "ConnectedViewController"
    
    public static var instance :ConnectedViewController!
    
    @IBOutlet weak var motion_info_txt: UILabel!
    @IBOutlet weak var ic_motion: UIImageView!
    
    @IBOutlet weak var container: UIView?
    private var subNavigationController :UINavigationController!
    private var standByViewController :StandByViewController!
    private var runningViewController :RunningViewController!
    
    private var jacket : Jacket!
    private var bluetoothController :BluetoothController!
    private var batteryLabel: UILabel?
    private var batteryIconView: UIImageView?
    private var batteryPill: UIVisualEffectView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ConnectedViewController.instance = self
        
        self.bluetoothController = BluetoothController.getInstance()
        self.standByViewController = self.subNavigationController.topViewController as? StandByViewController
        self.runningViewController = AppController.instantiate(id: String(describing: RunningViewController.self)) as? RunningViewController

        setupBatteryIndicator()
    }

    private func setupBatteryIndicator() {
        let pill = UIView.makeGlassPill(height: 28)
        pill.isHidden = true
        view.addSubview(pill)

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        pill.contentView.addSubview(iconView)

        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = .white
        lbl.textAlignment = .right
        pill.contentView.addSubview(lbl)

        NSLayoutConstraint.activate([
            pill.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            pill.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            iconView.leadingAnchor.constraint(equalTo: pill.contentView.leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: pill.contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            lbl.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 4),
            lbl.trailingAnchor.constraint(equalTo: pill.contentView.trailingAnchor, constant: -10),
            lbl.centerYAnchor.constraint(equalTo: pill.contentView.centerYAnchor)
        ])

        batteryPill = pill
        batteryIconView = iconView
        batteryLabel = lbl
    }

    private func updateBatteryDisplay() {
        let batteryVal = bluetoothController.getValue(uuid: JacketGattAttributes.BATTERY_LEVEL)
        guard batteryVal > 0 else {
            batteryPill?.isHidden = true
            return
        }

        let symbolName: String
        let tintColor: UIColor
        if batteryVal > 75 {
            symbolName = "battery.100"
            tintColor = UIColor(red: 0.20, green: 0.85, blue: 0.20, alpha: 1)
        } else if batteryVal > 50 {
            symbolName = "battery.75"
            tintColor = .white
        } else if batteryVal > 25 {
            symbolName = "battery.50"
            tintColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1)
        } else {
            symbolName = "battery.25"
            tintColor = UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1)
        }

        if #available(iOS 13.0, *) {
            batteryIconView?.image = UIImage(systemName: symbolName)
        }
        batteryIconView?.tintColor = tintColor
        batteryLabel?.text = "\(batteryVal)%"
        batteryLabel?.textColor = tintColor
        batteryPill?.isHidden = false
        batteryPill?.accessibilityLabel = "Battery level: \(batteryVal) percent"

        batteryPill?.layer.borderWidth = batteryVal <= 25 ? 1 : 0
        batteryPill?.layer.borderColor = tintColor.withAlphaComponent(0.4).cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.jacket = AppController.getCurrentJacket()
        
        bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_UPDATE_CHARACTERISTIC) { (param) in
            let params: [AnyObject] = param as! [AnyObject]
            guard let deviceID = params[0] as? String, deviceID == self.jacket?.id else { return }
            let uuid: CBUUID = params[1] as! CBUUID
            let value: Int = Int(params[2] as! String)!
            let intValue: Int = Int(value);
            
            switch(uuid.uuidString)
            {
            case JacketGattAttributes.MODE.uuidString:
                print("CONNECTED: MODE=",intValue);
                self.setMode(mode: intValue);
                break;
            case JacketGattAttributes.ACTIVITY_LEVEL.uuidString:
               self.setActivityLevel(value: intValue)
                break;
            case JacketGattAttributes.BATTERY_LEVEL.uuidString:
                self.updateBatteryDisplay()
                break;
            default:
                break
            }
        }
        self.setMode(mode: bluetoothController.getValue(uuid: JacketGattAttributes.MODE));
        self.setActivityLevel(value: bluetoothController.getValue(uuid: JacketGattAttributes.ACTIVITY_LEVEL));
        self.updateBatteryDisplay()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("CONNCTED_DISAPEAR");
        self.bluetoothController.removeListeners(id: TAG, eventNameToRemoveOrNil: nil)
        //subNavigationController?.viewControllers.removeAll()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embeded" {
            self.subNavigationController = segue.destination as? UINavigationController
        }
    }
    
    func setActivityLevel(value :Int)
    {
        let text :String = "Activity Sensor: %@"
        
        if(value==0)
        {
            self.motion_info_txt.text = String(format: text, "Static")
            self.ic_motion.image = UIImage(named: "ic_static")
            self.motion_info_txt.accessibilityLabel = "Activity sensor: Static. User is not moving."
        }else{
            self.motion_info_txt.text = String(format: text, "Moving")
            self.ic_motion.image = UIImage(named: "ic_moving")
            self.motion_info_txt.accessibilityLabel = "Activity sensor: Moving. User is in motion."
        }
    }
    
    func setMode(mode :Int)
    {
        print("CONNECTED SET MODE: ",mode)
        switch(mode){
        case JacketGattAttributes.PRE_MODE:
            self.setFragment(fragment: standByViewController)
        break
            case JacketGattAttributes.STANDBY_MODE:
                self.setFragment(fragment: standByViewController)
        break;
            case JacketGattAttributes.MANUAL_MODE:
                self.setFragment(fragment: runningViewController)
        break;
            case JacketGattAttributes.SMART_MODE:
                self.setFragment(fragment: runningViewController)
        break;
        default:
            // MODE 0 or unknown — some firmware builds omit valid MODE until later reads; treat as standby.
            if mode == 0 {
                self.setFragment(fragment: standByViewController)
            }
            break
        }
    }
    
    private func setFragment(fragment :UIViewController)
    {
        if(self.subNavigationController.topViewController != fragment)
        {
            if(fragment.navigationController != nil){
                self.subNavigationController.popToViewController(fragment, animated: true)
            }else{
                self.subNavigationController.pushViewController(fragment, animated: self.subNavigationController.topViewController==nil ? false : true)
            }
        }
    }
}

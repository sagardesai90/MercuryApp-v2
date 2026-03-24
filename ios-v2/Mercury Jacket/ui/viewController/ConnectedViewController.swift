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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ConnectedViewController.instance = self
        
        self.bluetoothController = BluetoothController.getInstance()
        self.standByViewController = self.subNavigationController.topViewController! as! StandByViewController//AppController.instantiate(id: String(describing: StandByViewController.self)) as! StandByViewController
        self.runningViewController = AppController.instantiate(id: String(describing: RunningViewController.self)) as! RunningViewController
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
            default:
                break
            }
        }
        self.setMode(mode: bluetoothController.getValue(uuid: JacketGattAttributes.MODE));
        self.setActivityLevel(value: bluetoothController.getValue(uuid: JacketGattAttributes.ACTIVITY_LEVEL));
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print("CONNCTED_DISAPEAR");
        self.bluetoothController.removeListeners(id: TAG, eventNameToRemoveOrNil: nil)
        //subNavigationController?.viewControllers.removeAll()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embeded" {
            self.subNavigationController = segue.destination as! UINavigationController
        }
    }
    
    func setActivityLevel(value :Int)
    {
        let text :String = "Activity Sensor: %@"
        
        if(value==0)
        {
            self.motion_info_txt.text = String(format: text, "Static")
            self.ic_motion.image = UIImage(named: "ic_static")
        }else{
            self.motion_info_txt.text = String(format: text, "Moving")
            self.ic_motion.image = UIImage(named: "ic_moving")
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
            //self.setFragment(fragment: standByViewController)
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

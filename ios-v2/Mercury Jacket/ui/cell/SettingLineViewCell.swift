//
//  SettingLineViewCell.swift
//  Mercury Jacket
//
//  Created by André Ponce on 12/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit
import LoginWithAmazon

class SettingLineViewCell: UITableViewCell, AIAuthenticationDelegate {
    
    @IBOutlet weak var title_txt: UILabel!
    @IBOutlet weak var switch_bt: UISwitch!
    
    private var jacket :Jacket!
    private var key :Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        switch_bt.tintColor = UIColor(hexString: "#10171F")
        switch_bt.layer.cornerRadius = 16
        switch_bt.backgroundColor = UIColor(hexString: "#10171F")
    }

    func setConfig(jacket: Jacket, key: Int, value: Bool)
    {
        self.jacket = jacket
        self.key = key
        
        self.title_txt.text = AppController.getSettingName(key: key)
        self.switch_bt.isOn = value
    }

    @IBAction func switch_handle(_ sender: Any) {
        if(key==Jacket.VOICE_CONTROL){
            if(!self.switch_bt.isOn){
                AMZNAuthorizationManager.shared().signOut { (error) in
                    if((error) != nil) {
                        print("error signing out: \(String(describing: error))")
                        self.switch_bt.isOn = true
                    } else {
                        print("Logout successfully!")
                        self.jacket.updateSetting(key: self.key, value: false)
                    }
                }
            }else{
                AIMobileLib.authorizeUser(forScopes: AppController.AMAZON_SCOPE, delegate: self);
            }
        }else{
            self.jacket.updateSetting(key: self.key, value: self.switch_bt.isOn)
        }
    }
    
    func requestDidSucceed(_ apiResult: APIResult!) {
        print("LWA Succeeded!")
        
        if (apiResult.api == API.authorizeUser) {
            AIMobileLib.getAccessToken(forScopes: AppController.AMAZON_SCOPE, withOverrideParams: nil, delegate: self)
        }
        else {
            let token = apiResult.result
            self.jacket.updateSetting(key: self.key, value: true)
            print("Success! Token: \(token ?? "nil")")
        }
    }
    
    func requestDidFail(_ errorResponse: APIError!) {
        print("Error: \(errorResponse.error.message ?? "nil")")
        AMZNAuthorizationManager.shared().signOut { (error) in}
        self.switch_bt.isOn = false
    }
}

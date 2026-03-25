//
//  Jacket.swift
//  MercuryJacket
//
//  Created by André Ponce on 14/11/2018.
//  Copyright © 2018 Quarky. All rights reserved.
//

import UIKit

class Jacket :Codable {
    
    public static let DEBUG                = 0;
    public static let VOICE_CONTROL        = 1;
    public static let BATTERY_NOTIFICATION = 2;
    public static let LOCATION_REQUEST     = 3;
    public static let MOTION_CONTROL       = 4;

    private static let defaultSettings :[Int:Bool] = [
        //DEBUG: false,
        VOICE_CONTROL: false,
        //BATTERY_NOTIFICATION: true,
        LOCATION_REQUEST: true,
        MOTION_CONTROL: true
    ]
    
    private var settings :[Int:Bool]? = nil
    
    var id   :String
    var name :String
    
    init(id :String, name :String){
        self.id = id;
        self.name = name;
    }
    
    public func getSetting(key :Int) ->Bool
    {
        return getSettings().keys.contains(key) ? getSettings()[key]! : false;
    }
    
    public func getSettings() ->[Int:Bool]
    {
        var tempSettings :[Int:Bool] = Jacket.defaultSettings;
        if(settings != nil)
        {
            for setting in tempSettings{
                if settings![setting.key] != nil {
                    tempSettings[setting.key] = settings![setting.key];
                }
            }
        }
        settings = tempSettings;
        return self.settings!
    }
    
    func save()
    {
        /*for entry in getSettings(){
            let name :String = AppController.getSettingName(key: entry.key)
            let value :String = "\(entry.value)"
        }*/
        AppController.addJacket(jacket: self);
    }
    
    public func delete()
    {
        AppController.removeJacket(jacket: self);
    }
    
    /// Updates the setting and syncs to BLE + persistence.
    public func updateSetting(key :Int, value :Bool)
    {
        if(BluetoothController.getInstance().isConnected() && key==Jacket.MOTION_CONTROL)
        {
            BluetoothController.getInstance().writeCharacteristic(uuid: JacketGattAttributes.MOTION_TEMP, value: value ? 1 : 0);
        }
        updateSettingLocal(key: key, value: value)
        save();
    }

    /// Updates only the in-memory setting without touching BLE or persistence.
    public func updateSettingLocal(key: Int, value: Bool) {
        _ = getSettings()
        self.settings![key] = value
    }
}

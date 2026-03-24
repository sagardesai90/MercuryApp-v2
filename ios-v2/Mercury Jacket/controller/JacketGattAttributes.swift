//
//  JacketGattAttributes.swift
//  Mercury Jacket
//
//  Created by Andre Ponce on 19/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit
import CoreBluetooth

class JacketGattAttributes {
    public static let serviceCBUUID :CBUUID = CBUUID(string: "1DF5BAEA-7CE1-4FA2-B31F-CF108FAEAAD2");
    
    public static let INTERNAL_TEMPERATURE :CBUUID = CBUUID(string: "2521d200-3748-4a52-9175-cbc8163a450c");
    public static let EXTERNAL_TEMPERATURE :CBUUID = CBUUID(string: "2973b788-15f2-4263-b412-8da09f3f87f9");
    public static let APP_TEMP             :CBUUID = CBUUID(string: "939B2D40-E498-4DFE-B7E7-FEB058CAC481");
    public static let POWER_OUTPUT         :CBUUID = CBUUID(string: "FB806B90-EC02-42FA-9641-E50D656E7BF6");
    public static let ACTIVITY_LEVEL       :CBUUID = CBUUID(string: "7e325bef-a17c-4f13-a0fe-9e49df91a8e2");
    public static let BATTERY_LEVEL        :CBUUID = CBUUID(string: "00002a19-0000-1000-8000-00805f9b34fb");
    public static let SET_LOW_TEMP         :CBUUID = CBUUID(string: "7669f03f-cbe5-4850-bb04-32797aba3b82");
    public static let SET_HIGH_TEMP        :CBUUID = CBUUID(string: "cedbd484-6965-4c96-8dbf-b9d3bac14332");
    public static let HIGH_TEMP_PT         :CBUUID = CBUUID(string: "EE4A5607-C1BE-4B4C-A602-A999CA4B585B");
    public static let LOW_TEMP_PT          :CBUUID = CBUUID(string: "802CE3F8-BACA-4CA7-9DD3-A7E56EF3BE26");
    
    public static let MODE                 :CBUUID = CBUUID(string: "7b46fb49-be72-4113-af8b-fa2bd5fd2c68");
    public static let POWER_LEVEL          :CBUUID = CBUUID(string: "f669680f-eb1d-4136-8b95-8852f0ec6a1a");
    public static let CONFIG               :CBUUID = CBUUID(string: "696D06B0-1B3E-4E18-AC62-384CEEBF6E68");
    public static let BOOT_DELAY           :CBUUID = CBUUID(string: "631492AB-333F-4701-885B-49A76F39098B");
    public static let PREHEAT_TIME         :CBUUID = CBUUID(string: "A223DC3B-2FAC-4353-B674-0D77E490B690");
    public static let PREHEAT_DELAY        :CBUUID = CBUUID(string: "4BF1A842-2B01-4F8E-B749-727C3F11A0BC");
    public static let NO_POWER_STARTUP_TIME:CBUUID = CBUUID(string: "A5DEA1D9-A86D-4904-B9CA-57EA4F54C3A4");
    public static let ACCEL_THRESHOLD_HI   :CBUUID = CBUUID(string: "6E7501B3-FE0A-42C8-A383-A1CA6DF57E1A");
    public static let ACCEL_THRESHOLD_LO   :CBUUID = CBUUID(string: "0F32CF12-8AE6-4209-823B-93A039369CAA");
    public static let MOTION_TEMP          :CBUUID = CBUUID(string: "A8D30C8E-D0D6-4A3E-8505-B0A13FDD9474");
    public static let NO_MOTION_TIME       :CBUUID = CBUUID(string: "57C9D431-2207-4ABE-8794-642710A33D70");
    public static let DEFAULT_MODE         :CBUUID = CBUUID(string: "AAFAA054-BA7E-427E-A456-C65F0D4D09B8");
    public static let SAVE_NV_SETTINGS     :CBUUID = CBUUID(string: "E0662BAA-0C2F-42CA-821C-F70465EDB6B4");
    public static let HOOK_1               :CBUUID = CBUUID(string: "D5B6929D-D140-4B3B-A8F0-7F2767C735C6");
    public static let HOOK_2               :CBUUID = CBUUID(string: "847E0167-C9AE-486D-A110-CD478486D90B");
    public static let HOOK_3               :CBUUID = CBUUID(string: "CBF93B1A-8584-4DE1-9125-5685EC767DE1");
    public static let HOOK_4               :CBUUID = CBUUID(string: "00E20DED-5FFB-40CE-82C0-52274EC47672");
    
    public static let STANDBY_MODE :Int = 1;
    public static let SMART_MODE   :Int = 2;
    public static let MANUAL_MODE  :Int = 3;
    public static let PRE_MODE     :Int = 4;
    
    private static let attributes          :[String:String] = [
        INTERNAL_TEMPERATURE.uuidString: "Internal Temperature",
        EXTERNAL_TEMPERATURE.uuidString: "External Temperature",
        APP_TEMP.uuidString: "App Temperature",
        POWER_OUTPUT.uuidString: "Power Output",
        ACTIVITY_LEVEL.uuidString: "Activity Level",
        BATTERY_LEVEL.uuidString: "Battery Level",
        SET_LOW_TEMP.uuidString: "Low Temp",
        SET_HIGH_TEMP.uuidString: "High Temp",
        LOW_TEMP_PT.uuidString: "Low Temp 10*K",
        HIGH_TEMP_PT.uuidString: "High Temp 10*K",
        MODE.uuidString: "Mode",
        POWER_LEVEL.uuidString: "Power Level",
        BOOT_DELAY.uuidString: "Boot Delay",
        PREHEAT_TIME.uuidString: "Preheat Time",
        PREHEAT_DELAY.uuidString: "Preheat Delay",
        NO_POWER_STARTUP_TIME.uuidString: "No Power Startup Time",
        ACCEL_THRESHOLD_HI.uuidString: "Accel Threshold High",
        ACCEL_THRESHOLD_LO.uuidString: "Accel Threshold Low",
        MOTION_TEMP.uuidString: "Motion Temperature",
        CONFIG.uuidString: "Config",
        NO_MOTION_TIME.uuidString: "No Motion Time",
        DEFAULT_MODE.uuidString: "Default Mode",
        SAVE_NV_SETTINGS.uuidString: "Save Non-volatile Settings",
        HOOK_1.uuidString: "Hook #1",
        HOOK_2.uuidString: "Hook #2",
        HOOK_3.uuidString: "Hook #3",
        HOOK_4.uuidString: "Hook #4"
    ]
    public static let readFormatMap :[String:Int]  = [:]
    public static let writeFormatMap :[String:Int] = [:]
    
    /*static {
     
     readFormatMap.put(INTERNAL_TEMPERATURE,BluetoothGattCharacteristic.FORMAT_SINT16);
     readFormatMap.put(EXTERNAL_TEMPERATURE,BluetoothGattCharacteristic.FORMAT_SINT16);
     readFormatMap.put(POWER_OUTPUT,BluetoothGattCharacteristic.FORMAT_UINT16);
     readFormatMap.put(ACTIVITY_LEVEL,BluetoothGattCharacteristic.FORMAT_UINT16);
     readFormatMap.put(POWER_LEVEL,BluetoothGattCharacteristic.FORMAT_UINT16);
     
     writeFormatMap.put(SET_LOW_TEMP,BluetoothGattCharacteristic.FORMAT_SINT16);
     writeFormatMap.put(SET_HIGH_TEMP,BluetoothGattCharacteristic.FORMAT_SINT16);
     writeFormatMap.put(POWER_LEVEL,BluetoothGattCharacteristic.FORMAT_UINT16);
     writeFormatMap.put(MODE,BluetoothGattCharacteristic.FORMAT_UINT8);
     }*/
    
    public static func getName(uuid :CBUUID) -> String {
        let name :String = attributes[uuid.uuidString]!
        return name;
    }
    
    public static func getReadFormat(uuid :CBUUID) -> Int {
        return  readFormatMap[uuid.uuidString] != nil ? readFormatMap[uuid.uuidString]! : 0;
    }
    
    public static func getWriteFormat(uuid :CBUUID) -> Int {
        return  writeFormatMap[uuid.uuidString] != nil ? writeFormatMap[uuid.uuidString]! : 0;
    }
}

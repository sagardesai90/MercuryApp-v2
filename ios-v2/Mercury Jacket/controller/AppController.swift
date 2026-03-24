//
//  AppController.swift
//  MercuryJacket
//
//  Created by André Ponce on 14/11/2018.
//  Copyright © 2018 Quarky. All rights reserved.
//

import UIKit
import CoreData

class AppController {
    
    public static var storyBoard :UIStoryboard =  UIStoryboard(name: "Main", bundle: nil)
    
    public static let KEY_JACKETS :String = "jackets"
    public static let KEY_CURRENT_JACKET :String = "current_jacket"
    public static let KEY_AMAZON_TOKEN :String = "amazon_token"
    public static let INPUT_HISTORY :String = "input_history"
    public static let KEY_MEASURE :String = "temperature_measure"
    public static let AMAZON_SCOPE :Array = ["profile"]
    
    public static let CELSIUS    :Int = 1;
    public static let FAHRENHEIT :Int = 2;
    public static let KELVIN     :Int = 3;
    public static var TEMPERATURE_MEASURE :Int = -1;
    
    private static var currentJacket :Jacket?;
    private static var bluetoothController :BluetoothController!
    
    public static var navigationController :UINavigationController? = nil
    
    private static let mapSettingsNames :[Int:String] = [
        //Jacket.DEBUG: "DEBUG",
        Jacket.VOICE_CONTROL: "Activate voice control through “Alexa”",
        //Jacket.BATTERY_NOTIFICATION: "Send Push notification when battery hits 15%",
        Jacket.LOCATION_REQUEST: "Allow location to be detected",
        Jacket.MOTION_CONTROL: "Enable Activity based Temperature control",
    ]
    
    public static func setup()
    {
        //checkVersion();
        
        /*let jacket1 = Jacket(id: "12345678", name: "Mercury")
        jacket1.save()
        
        let jacket2 = Jacket(id: "123456789", name: "Mercury 2")
        jacket2.save()
        
        let jacket3 = Jacket(id: "123456779", name: "Mercury 3")
        jacket3.save()
        
        let jacket4 = Jacket(id: "123456799", name: "Mercury 4")
        jacket4.save()*/
        
        bluetoothController = BluetoothController()
        SessionLogger.shared.start()
        if(currentJacket==nil && hasJacket()){
            var id :String = UserDefaults.standard.string(forKey: AppController.KEY_CURRENT_JACKET)!
            
            var jackets :[String:String]? = UserDefaults.standard.dictionary(forKey: KEY_JACKETS) as! [String : String]
            
            let jacket = try! JSONDecoder().decode(Jacket.self, from: (jackets![id]?.data(using: String.Encoding.utf8))!)
            
            currentJacket = jacket;
        }
        
        
        var data = UserDefaults.standard.array(forKey: INPUT_HISTORY)
        if(data == nil)
        {
            let arr = [
                ["2973B788-15F2-4263-B412-8DA09F3F87F9": 0, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
                ["2973B788-15F2-4263-B412-8DA09F3F87F9": 200, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 2000],
                ["2973B788-15F2-4263-B412-8DA09F3F87F9": 250, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
                ["2973B788-15F2-4263-B412-8DA09F3F87F9": 100, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 5000],
                ["2973B788-15F2-4263-B412-8DA09F3F87F9": 0, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
                ["2973B788-15F2-4263-B412-8DA09F3F87F9": -210, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
                ["2973B788-15F2-4263-B412-8DA09F3F87F9": -200, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 10000],
                ["2973B788-15F2-4263-B412-8DA09F3F87F9": 0, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 0],
                ["2973B788-15F2-4263-B412-8DA09F3F87F9": 500, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 0],
                ["2973B788-15F2-4263-B412-8DA09F3F87F9": 10, "F669680F-EB1D-4136-8B95-8852F0EC6A1A": 5000]
            ]
            UserDefaults.standard.set(arr, forKey: INPUT_HISTORY)
        }
    }
    
    public static func getSettingName(key :Int) ->String
    {
        return mapSettingsNames[key]!
        return "";
    }
    
    public static func getCurrentJacket() -> Jacket? {
        return currentJacket;
    }
    
    public static func addJacket(jacket :Jacket)
    {
        var data = UserDefaults.standard.dictionary(forKey: KEY_JACKETS)
        var jackets :[String:String] = data != nil ? data as! [String : String] : [:]
        
        let dataJacket: Data = try! JSONEncoder().encode(jacket)
        jackets[jacket.id] = String(data: dataJacket, encoding: String.Encoding.utf8)!
        
        UserDefaults.standard.set(jackets, forKey: KEY_JACKETS)
        
        if(getCurrentJacket() != nil && getCurrentJacket()?.id==jacket.id) {
            connectedTo(jacket: jacket);
        }
    }
    
    public static func removeJacket(jacket :Jacket)
    {
        var data = UserDefaults.standard.dictionary(forKey: KEY_JACKETS);
        var jackets :[String:String]? = data != nil ? data as! [String : String] :nil
        
        if(jackets != nil)
        {
            jackets?.removeValue(forKey: jacket.id)
            UserDefaults.standard.set(jackets, forKey: KEY_JACKETS)
        }
    
        if(getCurrentJacket() != nil && getCurrentJacket()?.id==jacket.id){
            currentJacket = nil;
            UserDefaults.standard.removeObject(forKey: KEY_CURRENT_JACKET)
        }
    }
    
    public static func getJacketsList() ->[Jacket]
    {
        var data = UserDefaults.standard.dictionary(forKey: KEY_JACKETS)
        var jacketsJson :[String:String]? = data != nil ? data as! [String : String] : nil
        
        let sorted = jacketsJson!.sorted(by: {$0.0 > $1.0})
        
        var jackets :[Jacket] = []
        
        for json in sorted
        {
            let jacket = try! JSONDecoder().decode(Jacket.self, from: (json.value.data(using: String.Encoding.utf8))!)
            jackets.append(jacket)
        }
        return jackets
    }
    
    public static func saveUserInput(newPowerLevel :Int)
    {
        var data = UserDefaults.standard.array(forKey: INPUT_HISTORY)
        var arr :[Dictionary<String,Int>] = data != nil ? data as! [Dictionary<String,Int>] : []
        var dic :Dictionary<String,Int> = Dictionary<String,Int>()
        
        let powerLevelUUID = JacketGattAttributes.POWER_LEVEL
        let externalTemperatureUUID = JacketGattAttributes.EXTERNAL_TEMPERATURE
        
        dic[powerLevelUUID.uuidString] = newPowerLevel//bluetoothController.getValue(uuid: powerLevelUUID)
        dic[externalTemperatureUUID.uuidString] = bluetoothController.getValue(uuid: externalTemperatureUUID)
        
        arr.append(dic)
        
        if(arr.count>10)
        {
            arr.removeFirst()
        }
        
        print("SAVED_USER_INPUT", arr, arr.count);
        
        UserDefaults.standard.set(arr, forKey: INPUT_HISTORY)
    }
    
    public static func getUserHistoryInput()->[Dictionary<String,Int>]
    {
        var data = UserDefaults.standard.array(forKey: INPUT_HISTORY)
        var arr :[Dictionary<String,Int>] = data != nil ? data as! [Dictionary<String,Int>] : []
        return arr
    }
    
    public static func connectedTo(jacket :Jacket?)
    {
        currentJacket = jacket;
    
        if(jacket != nil) {
            UserDefaults.standard.set(jacket!.id, forKey: KEY_CURRENT_JACKET)
        }
        else {
            UserDefaults.standard.removeObject(forKey: KEY_CURRENT_JACKET)
        }
    }
    
    public static func hasJacket() ->Bool
    {
        var data = UserDefaults.standard.string(forKey: AppController.KEY_CURRENT_JACKET)
        return data != nil
    }
    
    public static func hasJackets() -> Bool
    {
        var data = UserDefaults.standard.dictionary(forKey: KEY_JACKETS)
        var jackets :[String:String]? = data != nil ? data as! [String : String] : nil
    
        return jackets != nil ? (jackets?.count)!>0 : false;
    }
    
    public static func setTemperatureMeasure(value :Int)
    {
        TEMPERATURE_MEASURE = value;
        UserDefaults.standard.set(TEMPERATURE_MEASURE, forKey: KEY_MEASURE)
    }
    
    public static func getTemperatureMeasure()->Int
    {
        if(TEMPERATURE_MEASURE<0) {
            TEMPERATURE_MEASURE = UserDefaults.standard.integer(forKey: AppController.KEY_MEASURE)
        }
        return TEMPERATURE_MEASURE;
    }
    
    public static func celsiusToFahrenheit(value :Float) -> Float
    {
        return ((value*(9.0/5))+32);
    }
    
    public static func fahrenheitToCelsius(value :Float) -> Float
    {
        return ((value-32)/(9.0/5));
    }
    
    public static func instantiate(id :String) -> UIViewController
    {
        return AppController.storyBoard.instantiateViewController(withIdentifier: id)
    }
    
    public static func startViewController(viewController :UIViewController, clearStack :Bool = false)
    {
        if(viewController != nil)
        {
            DispatchQueue.main.async() {
                // CATransaction.begin()
                //CATransaction.setCompletionBlock({ () -> Void in
                
                //})
                let context = getContext()
                
                navigationController?.pushViewController(viewController, animated: true)
                if(clearStack)
                {
                    let navVCsCount = navigationController?.viewControllers.count;
                    if(navVCsCount! > 1)
                    {
                        var i :Int = 0;
                        navigationController!.viewControllers.removeSubrange(Range(i..<navVCsCount! - 1))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            print("VIEWS: ",navigationController?.viewControllers);
                        }
                    }
                }
                //CATransaction.commit()
            }
        }
    }
    
    public static func removeViewControllerFromStack(view :UIViewController)
    {
        if(navigationController != nil && navigationController?.viewControllers != nil && view != nil)
        {
            let index = (navigationController?.viewControllers.lastIndex(of: view))
            if(index != nil && index! > -1)
            {
                navigationController?.viewControllers.remove(at: index!)
                print("NEW STACK:", navigationController?.viewControllers);
            }
        }
    }
    
    public static func getContext() ->UIViewController
    {
        return  (navigationController?.viewControllers[(navigationController?.viewControllers.count)!-1])!
    }
}

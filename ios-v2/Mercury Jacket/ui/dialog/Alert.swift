//
//  Alert.swift
//  Desafieme
//
//  Created by André Ponce on 16/10/2018.
//  Copyright © 2018 Quarky. All rights reserved.
//
import UIKit
import Foundation

class Alert
{
    private static var INSTANCE :Alert? = nil;
    
    public static let CONFIRM :Int = 0;
    public static let ASK     :Int = 1;
    public static let WAIT    :Int = 2;
    public static let LOADER  :Int = 3;
    
    public static let CONFIRM_ACTION :Int = 0;
    public static let YES_ACTION     :Int = 1;
    public static let NO_ACTION      :Int = 2;
    
    public var confirmMessage :String = "ok";
    public var yesMessage     :String = "Yes";
    public var noMessage      :String = "No";
    
    private var context :UIViewController;
    private var listener :ActionListener? = nil;
    private var alertController :UIAlertController? = nil;
    
    init(context :UIViewController){
        self.context = context;
        if(Alert.INSTANCE != nil) {
            Alert.INSTANCE?.dismiss();
        }
        Alert.INSTANCE = self;
    }
    
    class ActionListener{
        //public func onActionClick(action :Int) {}
        var onActionClick :((_ action :Int) -> Void);
        init(onActionClick :@escaping (_ action :Int) -> Void)
        {
            self.onActionClick = onActionClick;
        }
    }
    
    public func setActionListener(listener :ActionListener) {
        self.listener = listener;
    }
    
    public static func show(context :UIViewController, message :String) -> Alert
    {
        let alert :Alert = Alert(context: context);
        alert.create(message: message,type: Alert.CONFIRM);
        alert.show();
        return alert;
    }
    
    public func create(message :String, type :Int)
    {
        self.alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertController.Style.alert);
        
        switch(type)
        {
        case Alert.CONFIRM:
            self.addAction(title: self.confirmMessage, code: Alert.CONFIRM_ACTION);
            break;
        case Alert.ASK:
            self.addAction(title: self.yesMessage, code: Alert.YES_ACTION);
            self.addAction(title: self.noMessage, code: Alert.NO_ACTION);
            break;
        default: break
        }
    }
    
    private func addAction(title :String, code :Int)
    {
        self.alertController?.addAction(UIAlertAction(title: title, style: code == Alert.NO_ACTION ? UIAlertAction.Style.cancel : UIAlertAction.Style.default, handler: { (action) in
            self.listener?.onActionClick(code)
        }))
    }
    
    public func show()
    {
        if(self.alertController != nil) {
            print("SHOW ALERT");
            self.context.present(self.alertController!, animated: true, completion: nil)
        }
    }
    
    public func dismiss()
    {
        if(self.alertController != nil)
        {
            print("DISMISS ALERT");
            self.alertController?.removeFromParent()
            self.alertController?.dismiss(animated: false, completion: nil)
            self.alertController = nil
        }
    }
}

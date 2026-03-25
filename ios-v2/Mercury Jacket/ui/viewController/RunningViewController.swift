//
//  RunningViewController.swift
//  Mercury Jacket
//
//  Created by André Ponce on 11/12/18.
//  Copyright © 2018 Cappen. All rights reserved.
//

import UIKit
import CoreBluetooth

class RunningViewController: BaseViewController {

    public var TAG :String = "RunningViewController"
    
    @IBOutlet weak var preloader_image: UIImageView!
    @IBOutlet weak var slider_bar: UIView!
    @IBOutlet weak var container_mask_bar: UIView!
    @IBOutlet weak var bar_image: UIImageView!
    @IBOutlet weak var smart_bt: UIButton!
    @IBOutlet weak var manual_bt: UIButton!
    @IBOutlet weak var status_txt: UILabel!
    @IBOutlet weak var info_bt: UIButton!
    @IBOutlet weak var manualInfo: UIView!
    @IBOutlet weak var debug_view: UIView!
    @IBOutlet weak var debug_read_status_txt: UITextView!
    @IBOutlet weak var debug_write_status_txt: UITextView!
    
    @IBOutlet weak var mask_view: UIView!
    @IBOutlet weak var bg_image: UIImageView!
    @IBOutlet weak var mask_constraint: NSLayoutConstraint!
    
    private var bluetoothController :BluetoothController!
    private var learningTimer: Timer? = nil
    private var level :Float = 10
    private var isReady :Bool = false
    private var isSmartMode :Bool = false
    private var learning :Bool = false
    private var learned :Bool = false
    private var debug :Bool = false
    private var debugCount :Int = 0
    
    private var sliderGlassView: UIVisualEffectView?
    private var sliderGlassLeadingConstraint: NSLayoutConstraint?
    private var sliderGlassTrailingConstraint: NSLayoutConstraint?
    private var sliderGlassTopConstraint: NSLayoutConstraint?
    private var sliderGlassBottomConstraint: NSLayoutConstraint?
    /// Background art with level tick marks — must sit *below* the glass so UIGlassEffect can sample it.
    private weak var sliderBackgroundImageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bluetoothController = BluetoothController.getInstance()
        
        manual_bt.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        smart_bt.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        
        info_bt.isHidden = true
        status_txt.isHidden = true
        smart_bt.isUserInteractionEnabled = false
        manual_bt.isUserInteractionEnabled = false
        debug_view.isHidden = true

        smart_bt.accessibilityLabel = "Smart mode"
        smart_bt.accessibilityHint = "Activates automatic temperature adjustment based on activity"
        manual_bt.accessibilityLabel = "Manual mode"
        manual_bt.accessibilityHint = "Allows manual control of heating level"
        info_bt.accessibilityLabel = "About smart mode"
        slider_bar.accessibilityLabel = "Heating level slider"
        
        let checkInfo = UserDefaults.standard.bool(forKey: "info")
        if(checkInfo)
        {
            manualInfo.isHidden = true
        }
        
        self.preloader_image.isUserInteractionEnabled = true
        self.preloader_image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(preloaderTapped(tapGestureRecognizer:))))

        setupSliderGlass()
        relocateSliderBackgroundUnderGlass()
    }

    /// Puts `bg_temperature_controller` under the glass inside the track container. When it was a sibling
    /// behind the whole container, the glass only blurred empty/black space — lines never showed through.
    private func relocateSliderBackgroundUnderGlass() {
        guard let slider = slider_bar, let container = container_mask_bar else { return }
        guard let bg = slider.subviews.first(where: { $0 is UIImageView }) as? UIImageView else { return }
        sliderBackgroundImageView = bg
        bg.removeFromSuperview()
        bg.translatesAutoresizingMaskIntoConstraints = false
        container.insertSubview(bg, at: 0)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: container.topAnchor),
            bg.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        // Stack (back → front): bg art → masked red fill → glass, so the heat color reads through the liquid glass.
        if let g = sliderGlassView {
            container.bringSubviewToFront(g)
        }
        clearSliderChromeBorders()
    }

    private func clearSliderChromeBorders() {
        slider_bar.layer.borderWidth = 0
        container_mask_bar?.layer.borderWidth = 0
        mask_view?.layer.borderWidth = 0
        bar_image?.layer.borderWidth = 0
        sliderGlassView?.layer.borderWidth = 0
        sliderGlassView?.layer.borderColor = nil
        sliderBackgroundImageView?.layer.borderWidth = 0
    }

    private func setupSliderGlass() {
        guard let bar = container_mask_bar else { return }
        slider_bar.clipsToBounds = false
        // Glass is inset -1% on each edge (slightly larger than the track); must not clip the overflow.
        bar.clipsToBounds = false
        bar.layer.masksToBounds = false
        bar.layer.borderWidth = 0
        // Build the effect view here so iOS 26 always gets UIGlassEffect (liquid glass), not only via the shared helper path.
        // `.clear` / ultra-thin blur keeps the track readable without the heavy dark veil of `.regular` / `systemMaterialDark`.
        let glass: UIVisualEffectView
        if #available(iOS 26.0, *) {
            glass = UIVisualEffectView(effect: UIGlassEffect(style: .clear))
        } else {
            glass = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        }
        glass.translatesAutoresizingMaskIntoConstraints = false
        glass.isOpaque = false
        glass.backgroundColor = .clear
        // Rounded overscan matches `container_mask_bar` squircle in `syncSliderGlassCornerRadius`.
        glass.clipsToBounds = true
        glass.layer.borderWidth = 0
        // Glass sits above the red fill; must not steal drags from the track.
        glass.isUserInteractionEnabled = false
        bar.insertSubview(glass, at: 0)
        let top = glass.topAnchor.constraint(equalTo: bar.topAnchor, constant: 0)
        let lead = glass.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 0)
        let trail = glass.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: 0)
        let bot = glass.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: 0)
        NSLayoutConstraint.activate([top, lead, trail, bot])
        sliderGlassLeadingConstraint = lead
        sliderGlassTrailingConstraint = trail
        sliderGlassTopConstraint = top
        sliderGlassBottomConstraint = bot
        sliderGlassView = glass
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        syncSliderGlassCornerRadius()
    }

    /// Squircle on the track container only. Applying the same radius to bg + glass + bar caused sub-pixel drift at corners (black “peek”).
    /// Red fill = `bar_image` (power level), not glass. Liquid glass is between bg art and the mask; red sits above the glass in the fill region.
    private func syncSliderGlassCornerRadius() {
        guard let bar = container_mask_bar, let glass = sliderGlassView else { return }
        let w = bar.bounds.width
        let h = bar.bounds.height
        guard w > 0, h > 0 else { return }
        let shorter = min(w, h)
        let r = min(36, max(16, shorter * 0.22))
        // Glass is ~1% larger on each side than the track; match radius to the expanded squircle.
        let overscan: CGFloat = 0.01
        let rGlass = r * (1 + 2 * overscan)
        let dx = w * overscan
        let dy = h * overscan
        sliderGlassLeadingConstraint?.constant = -dx
        sliderGlassTrailingConstraint?.constant = dx
        sliderGlassTopConstraint?.constant = -dy
        sliderGlassBottomConstraint?.constant = dy
        if #available(iOS 13.0, *) {
            bar.layer.cornerCurve = .continuous
        }
        bar.layer.cornerRadius = r
        bar.layer.masksToBounds = false
        bar.clipsToBounds = false

        glass.layer.cornerRadius = rGlass
        glass.layer.masksToBounds = true
        if #available(iOS 13.0, *) {
            glass.layer.cornerCurve = .continuous
        }

        sliderBackgroundImageView?.layer.cornerRadius = 0
        sliderBackgroundImageView?.clipsToBounds = false

        mask_view?.layer.cornerRadius = 0
        mask_view?.clipsToBounds = true

        bar_image?.layer.cornerRadius = 0
        bar_image?.clipsToBounds = false

        // Keep glass above the masked fill so red shows through the material.
        if let g = sliderGlassView {
            bar.bringSubviewToFront(g)
        }

        clearSliderChromeBorders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        bluetoothController.listenTo(id: TAG, eventName: BluetoothController.Events.ON_UPDATE_CHARACTERISTIC) { (param) in
            let params: [AnyObject] = param as! [AnyObject]
            guard let deviceID = params[0] as? String,
                  deviceID == AppController.getCurrentJacket()?.id else { return }
            let uuid: CBUUID = params[1] as! CBUUID
            let value: Int = Int(params[2] as! String)!
            let intValue: Int = Int(value);
            
            switch(uuid.uuidString)
            {
            case JacketGattAttributes.POWER_LEVEL.uuidString:
                
                if(!self.learning || (self.learning && self.learned)){
                    if(self.learning)
                    {
                        self.stopLearning(stopAnimation: false)
                    }
                    self.setPowerLevel(value: intValue)
                }
                
                break;
            case JacketGattAttributes.MODE.uuidString:
                self.setMode(value: intValue);
                
                break;
            default:
                break
            }
        }
        
        self.bluetoothController.readCharacteristic(uuid: JacketGattAttributes.MODE)
        self.bluetoothController.readCharacteristic(uuid: JacketGattAttributes.POWER_LEVEL)
        
        self.setMode(value: bluetoothController.getValue(uuid: JacketGattAttributes.MODE));
        self.setPowerLevel(value: bluetoothController.getValue(uuid: JacketGattAttributes.POWER_LEVEL))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if(animTimer != nil)
        {
            animTimer.invalidate()
            animTimer = nil
        }
        self.stopLearning(stopAnimation: true)
        self.bluetoothController.removeListeners(id: TAG, eventNameToRemoveOrNil: nil)
    }
    
    @objc func preloaderTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if(!self.debug)
        {
            self.debugCount = self.debugCount+1
            if(self.debugCount>=10)
            {
                self.debug = true
                self.debug_view.isHidden = false
                
                Timer.scheduledTimer(withTimeInterval: TimeInterval(2), repeats: true) { timer in
                    self.updateDebugStatus();
                }
            }
        }
    }
    
    private func updateDebugStatus()
    {
        if(debug)
        {
            let characteristics = bluetoothController.getCharacteristics()
            
            var text :String = ""
            
            for characteristic in characteristics
            {
                text += JacketGattAttributes.getName(uuid: characteristic.key)+" = \(self.bluetoothController.getValue(uuid: characteristic.key))\n"
            }
            
            text += "**************************\n"
            
            let oldText = debug_read_status_txt.text.prefix(1000)
            debug_read_status_txt.text = text+oldText
        }
    }
    
    private func updateDebugWrite(text :String)
    {
        if(debug)
        {
            let oldText = debug_write_status_txt.text.prefix(1000)
            debug_write_status_txt.text = text+"\n"+oldText
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let currentPoint = touch.location(in: container_mask_bar)
            
            let x :CGFloat = currentPoint.x;
            let y :CGFloat = currentPoint.y;
            if(x>0 && x<container_mask_bar.frame.width && y>0 && y<container_mask_bar.frame.height+20)
            {
                self.updateDrag(point: currentPoint)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let currentPoint = touch.location(in: container_mask_bar)
            
            let x :CGFloat = currentPoint.x;
            let y :CGFloat = currentPoint.y;
            if(x>0 && x<container_mask_bar.frame.width && y>0 && y<container_mask_bar.frame.height+20)
            {
                self.updateDrag(point: currentPoint)
            }
        }
    }
    
    private func updateDrag(point :CGPoint)
    {
        if(isReady)
        {
            var dy :Float = 0;
            dy = Float(point.y)
            dy = max(0,min(dy,Float(self.container_mask_bar.frame.height)));
            
            let pct :Float = dy / Float(self.container_mask_bar.frame.height);
            
            let value :Float = abs(floor(pct*10)-10);
            let newPowerLevel :Int = Int(value*1000);
            
            if(self.level != value)
            {
                UISelectionFeedbackGenerator().selectionChanged()
                if(!isSmartMode)
                {
                    self.bluetoothController.writeCharacteristic(uuid: JacketGattAttributes.POWER_LEVEL, value: newPowerLevel)
                    self.updateDebugWrite(text: "\(JacketGattAttributes.getName(uuid: JacketGattAttributes.POWER_LEVEL)) = \(newPowerLevel)")
                }else{
                    self.startLearning(newPowerLevel: newPowerLevel)
                }
            }
            updateLevel(level: value, animate: false);
        }
    }
    
    var animTimer :Timer!
    
    func updateLevel(level :Float, animate :Bool)
    {
        self.level = level
        
        if(animTimer != nil)
        {
            animTimer.invalidate()
            animTimer = nil
        }
        let finalValue = max(CGFloat(level/10.0),0.0001)
        if(animate)
        {
            var value = self.mask_constraint.multiplier
            animTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.03), repeats: true) { timer in
                value += (finalValue-self.mask_constraint.multiplier)*0.2
                self.mask_constraint = self.mask_constraint.setMultiplier(multiplier: value)
                if((Double(String(format: "%.3f", finalValue))!-Double(String(format: "%.3f", value))!)==0){
                    self.animTimer.invalidate()
                    self.animTimer = nil
                }
            }
        }else{
            self.mask_constraint = self.mask_constraint.setMultiplier(multiplier: finalValue)
        }
        
        if(learningTimer == nil)
        {
            self.preloader_image.stopAnimatingGif()
            if(level<=0)
            {
                self.preloader_image.showFrameAtIndex(4)
            }else if(level>0 && level<4)
            {
                self.preloader_image.showFrameAtIndex(13)
            }else if(level>=4 && level<=7){
                self.preloader_image.showFrameAtIndex(25)
            }else if(level>7){
                self.preloader_image.showFrameAtIndex(34)
            }
        }
    }
    
    private func calculateSmartPower(newPowerLevel: Int? = nil)
    {
        let powerLevelUUID = JacketGattAttributes.POWER_LEVEL
        let externalTemperatureUUID = JacketGattAttributes.EXTERNAL_TEMPERATURE
        var arr = AppController.getUserHistoryInput()
        /*[
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
        ]*/
        if(newPowerLevel != nil)
        {
            arr.removeFirst()
            arr.append([powerLevelUUID.uuidString: newPowerLevel!, externalTemperatureUUID.uuidString: self.bluetoothController.getValue(uuid: externalTemperatureUUID)])
            AppController.saveUserInput(newPowerLevel: newPowerLevel!)
        }
        
        var tableStr = ""
        
        let n = Double(arr.count)
        var Exy  = 0.0
        var Ex   = 0.0
        var Ey   = 0.0
        var xm   = 0.0
        var ym   = 0.0
        var Ex2  = 0.0
        var Ex_2 = 0.0
        var Ey2  = 0.0
        //var Ey_2 = 0.0
        
        for dic in arr
        {
            let x = Double(dic[externalTemperatureUUID.uuidString]!)
            let y = Double(dic[powerLevelUUID.uuidString]!)
            Exy = Exy+(x*y)
            Ex = Ex+x
            Ey = Ey+y
            Ex2 = Ex2+pow(Double(x), 2)
            Ey2 = Ey2+pow(Double(y), 2)
            
            tableStr += "(\(Int(x)), \(Int(y)))\n"
        }
        xm = Ex/n
        ym = Ey/n
        Ex_2 = pow(Double(Ex), 2)
        //Ey_2 = pow(Double(Ey), 2)
        
        var m = (n*Exy-Ex*Ey)/(n*Ex2-Ex_2)
        m = m.isNaN || m==0 ? -0.001 : m
        let b = ym-m*xm
        
        let low_temp = Int(round((10000-b)/m))//Int(min(max(m*10000+b,-15),0))
        let high_temp = Int(round((-b)/m))//Int(max(min(b,25),0))
        
        //print(arr)
        print("low_temp: ",low_temp,"high_temp: ",high_temp, "m: ",m)
        
        self.bluetoothController.writeCharacteristic(uuid: JacketGattAttributes.SET_LOW_TEMP, value: low_temp)
        self.bluetoothController.writeCharacteristic(uuid: JacketGattAttributes.SET_HIGH_TEMP, value: high_temp)
        self.bluetoothController.writeCharacteristic(uuid: JacketGattAttributes.SAVE_NV_SETTINGS, value: 1)
        self.updateDebugWrite(text: "*******************")
        self.updateDebugWrite(text: "\(JacketGattAttributes.getName(uuid: JacketGattAttributes.SET_LOW_TEMP)) = \(low_temp)")
        self.updateDebugWrite(text: "\(JacketGattAttributes.getName(uuid: JacketGattAttributes.SET_HIGH_TEMP)) = \(high_temp)")
        self.updateDebugWrite(text: "\(JacketGattAttributes.getName(uuid: JacketGattAttributes.SAVE_NV_SETTINGS)) = \(1)")
        
        self.updateDebugWrite(text: "high_temp = -b/m")
        self.updateDebugWrite(text: "low_temp = (10000-b)/m")
        self.updateDebugWrite(text: "b = \(b)")
        self.updateDebugWrite(text: "m = \(m)")
        self.updateDebugWrite(text: tableStr)
        self.updateDebugWrite(text: "*******************")
        
        self.learned = true
    }
    
    private func startLearning(newPowerLevel: Int)
    {
        self.learning = true
        //self.status_txt.text = "Mercury is learning..."
        self.status_txt.isHidden = false
        self.preloader_image.startAnimatingGif()
        
        self.learningTimer?.invalidate()
        learningTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(2), repeats: false) { timer in
            self.calculateSmartPower(newPowerLevel: newPowerLevel);
        }
    }
    
    private func stopLearning(stopAnimation: Bool)
    {
        self.learning = false
        self.learned = false
        self.status_txt.isHidden = true
        if(stopAnimation)
        {
            self.preloader_image.stopAnimatingGif()
        }
        self.learningTimer?.invalidate()
        self.learningTimer = nil
        //self.setPowerLevel(value: self.bluetoothController.getValue(uuid: JacketGattAttributes.POWER_LEVEL))
    }

    @IBAction func info_handle(_ sender: Any) {
        let v = AppController.instantiate(id: String(describing: AboutViewController.self))
        v.modalPresentationStyle = .overCurrentContext
        AppController.getContext().present(v, animated: true, completion: nil);
    }
    
    @IBAction func smart_handle(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        self.smartMode(update: true)
    }
    
    @IBAction func manual_handle(_ sender: Any) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        self.manualMode(update: true);
    }
    
    @IBAction func close_info_handle(_ sender: Any) {
        manualInfo.isHidden = true
        UserDefaults.standard.set(true, forKey: "info")
    }
    
    func setPowerLevel(value :Int)
    {
        let level :Float = Float(round(Double(value) / 1000.0));
        self.updateLevel(level: level, animate: true)
    }
    
    private func setMode(value :Int)
    {
        if(animTimer != nil)
        {
            animTimer.invalidate()
            animTimer = nil
        }
        
        print("RUNNING: MODE=", value);
        switch(value){
        case JacketGattAttributes.MANUAL_MODE:
            manualMode(update: false);
            break;
        case JacketGattAttributes.SMART_MODE:
            smartMode(update: false);
            break;
        /*case DashBoardViewController.STANDBY_MODE:
            ConnectedViewController.instance.setMode(mode: DashBoardViewController.STANDBY_MODE)
            break;*/
        default:
            smartMode(update: false);
            break;
        }
    }
    
    public func manualMode(update :Bool)
    {
        self.isReady = true
         self.isSmartMode = false
        
        self.stopLearning(stopAnimation: true)
        info_bt.isHidden = true
        
        bar_image.tintColor = UIColor(hexString: "#E05656")
        preloader_image.setGifImage(UIImage(gifName: "circle_loader_red"))
        preloader_image.loopCount = 0
        preloader_image.stopAnimatingGif()
        
        smart_bt.setImage(UIImage(named: "smart_bt_inactive"), for: UIControl.State.normal)
        manual_bt.setImage(UIImage(named: "manual_bt_active"), for: UIControl.State.normal)
        smart_bt.isUserInteractionEnabled = true
        manual_bt.isUserInteractionEnabled = false

        updateLevel(level: self.level, animate: true);
        
        self.bluetoothController.readCharacteristic(uuid: JacketGattAttributes.POWER_LEVEL)
        
        if(update)
        {
            bluetoothController.writeCharacteristic(uuid: JacketGattAttributes.MODE,value: JacketGattAttributes.MANUAL_MODE);
            self.updateDebugWrite(text: "\(JacketGattAttributes.getName(uuid: JacketGattAttributes.MODE)) = \(JacketGattAttributes.MANUAL_MODE)")
        }
    }
    
    public func smartMode(update :Bool)
    {
        self.isReady = true
        self.isSmartMode = true
        
        info_bt.isHidden = false
        
        bar_image.tintColor = UIColor(hexString: "#00B200")
        preloader_image.setGifImage(UIImage(gifName: "circle_loader_green"))
        preloader_image.stopAnimatingGif()
        
        manual_bt.setImage(UIImage(named: "manual_bt_inactive"), for: UIControl.State.normal)
        smart_bt.setImage(UIImage(named: "smart_bt_active"), for: UIControl.State.normal)
        smart_bt.isUserInteractionEnabled = false
        manual_bt.isUserInteractionEnabled = true

        updateLevel(level: self.level, animate: true);
        
        self.bluetoothController.readCharacteristic(uuid: JacketGattAttributes.POWER_LEVEL)
        
        if(update) {
            bluetoothController.writeCharacteristic(uuid: JacketGattAttributes.MODE,value: JacketGattAttributes.SMART_MODE);
            bluetoothController.writeCharacteristic(uuid: JacketGattAttributes.MODE,value: JacketGattAttributes.SMART_MODE);
            self.updateDebugWrite(text: "\(JacketGattAttributes.getName(uuid: JacketGattAttributes.MODE)) = \(JacketGattAttributes.SMART_MODE)")
        }else{
            self.calculateSmartPower();
        }
    }
}

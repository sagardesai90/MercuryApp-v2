//
//  UINibView.swift
//  Desafieme
//
//  Created by André Ponce on 08/11/2018.
//  Copyright © 2018 Quarky. All rights reserved.
//

import UIKit

@IBDesignable
class UINibView: UIView {
    
    var view :UIView!
    
    override func prepareForInterfaceBuilder () {
        super.prepareForInterfaceBuilder ()
        nibSetup()
        self.view.prepareForInterfaceBuilder()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
    }
    
    func nibSetup() {
        backgroundColor = .clear
        
        let view :UIView = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true
        
        self.view = view;
        
        addSubview(view)
    }
    
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
    
    private func loadViewFromNib() -> UIView {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let nibView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        return nibView
    }
}

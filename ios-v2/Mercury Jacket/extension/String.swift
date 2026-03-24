//
//  StringViewController.swift
//  Desafieme
//
//  Created by André Ponce on 17/11/2018.
//  Copyright © 2018 Quarky. All rights reserved.
//

import UIKit

extension String {
    
    init(htmlString: String) {
        self.init()
        guard let encodedData = htmlString.data(using: .utf8) else {
            self = htmlString
            return
        }
        
        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey : Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            let attributedString = try NSAttributedString(data: encodedData,
                                                          options: attributedOptions,
                                                          documentAttributes: nil)
            self = attributedString.string
        } catch {
            print("Error: \(error.localizedDescription)")
            self = htmlString
        }
    }
}

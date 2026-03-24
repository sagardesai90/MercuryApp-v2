//
//  NSAttributedStringViewController.swift
//  Desafieme
//
//  Created by André Ponce on 17/11/2018.
//  Copyright © 2018 Quarky. All rights reserved.
//

import UIKit

extension NSAttributedString {
    
    convenience init(htmlString html: String) throws {
        try self.init(data: Data(html.utf8), options: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil)
    }
    
}

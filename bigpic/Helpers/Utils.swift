//
//  Utils.swift
//  bigpic
//
//  Created by Cristian Sava on 22.09.20.
//  Copyright © 2020 Cristian Sava. All rights reserved.
//

import Foundation
import UIKit

struct Utils {
    
    static let documentsPath: String = {
        let URLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return URLs[0].path
    }()
    
    static func createAlert(withText text: String, asError: Bool = true) -> UIAlertController {
        let alert = UIAlertController(title: asError ? "Error" : "", message: text, preferredStyle: UIAlertController.Style.alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(defaultAction)
        
        return alert
    }
}

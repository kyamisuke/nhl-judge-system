//
//  UIDeviceEx.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/06/06.
//

import SwiftUI

extension UIDevice {
    var isiPhone: Bool {
        return userInterfaceIdiom == .phone
    }
    
    var isiPad: Bool {
        return userInterfaceIdiom == .pad
    }
}

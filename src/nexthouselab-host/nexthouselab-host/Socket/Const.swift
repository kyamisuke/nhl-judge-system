//
//  Const.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/27.
//

import SwiftUI

class Const {
    static let SELCTED_FILE_KEY = "selected_file_cocntents"
    static let FILE_NAME_KEY = "file_name"
    static let IP_KEY = "ip_key"
    static let HOST_KEY = "host_key"
    static let SCORES_KEY = "scores"
    static let JUDGE_NAMES = [JudgeName(name: "HOAN"), JudgeName(name: "CLARA"), JudgeName(name: "ANTHONY THOMAS"), JudgeName(name: "MAJID")]
    
    static let exportColor = Color("exportButton")
    static let importColor = Color("importButton")
    static let judgeLabelColor = Color(hue: 0, saturation: 0, brightness: 0.9)
    
    enum Mode: String, CaseIterable, Identifiable {
        case Solo
        case Dual
        
        var id: String { self.rawValue }
        
        func playerNum() -> Int {
            switch self {
            case .Solo:
                return 1
            case .Dual:
                return 2
            }
        }
    }
}

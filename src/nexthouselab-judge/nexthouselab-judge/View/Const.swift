//
//  File.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/22.
//

import SwiftUI

class Const {
    static let SELCTED_FILE_KEY = "selected_file_cocntents"
    static let FILE_NAME_KEY = "file_name"
    static let JUDGE_NAME_KEY = "judge_name"
    static let HOST_IP_KEY = "host_ip"
    static let HOST_KEY = "host"
    static let SCORE_KEY = "scores"
    static let DONE_STATES_KEY = "done_states"
    static let CURRENT_PLAY_NUM_KEY = "current_play_num_key"
    
    enum Mode: String, CaseIterable, Identifiable {
        case Solo
        case Dual
        
        var id: String { self.rawValue }
        
        var playerNum: Int {
            switch self {
            case .Solo:
                return 1
            case .Dual:
                return 2
            }
        }
    }
}

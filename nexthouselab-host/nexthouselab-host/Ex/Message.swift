//
//  Message.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/21.
//

import Foundation

struct Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.judgeName == rhs.judgeName && lhs.number == rhs.number
    }
    
    var judgeName: String
    var number: Int
}

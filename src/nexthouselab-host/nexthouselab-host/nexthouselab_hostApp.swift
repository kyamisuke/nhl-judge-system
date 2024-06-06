//
//  nexthouselab_hostApp.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI

@main
struct nexthouselab_hostApp: App {
    @StateObject var socketManager = SocketManager()
    @StateObject var scoreModel = ScoreModel()
    
    var body: some Scene {
        WindowGroup {
            if UIDevice.current.isiPad {
                MainView()
                    .environmentObject(socketManager)
                    .environmentObject(scoreModel)
            } else if UIDevice.current.isiPhone {
                PhoneMainView()
                    .environmentObject(socketManager)
                    .environmentObject(scoreModel)
            }
        }
    }
}

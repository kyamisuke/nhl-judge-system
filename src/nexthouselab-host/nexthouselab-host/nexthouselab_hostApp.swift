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
            MainView()
                .environmentObject(socketManager)
                .environmentObject(scoreModel)
        }
    }
}

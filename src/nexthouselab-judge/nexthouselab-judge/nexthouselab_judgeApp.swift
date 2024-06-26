//
//  nexthouselab_judgeApp.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/06.
//

import SwiftUI

@main
struct nexthouselab_judgeApp: App {
    @StateObject var socketManager = SocketManager()
    @StateObject var scoreModel = ScoreModel()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(socketManager)
                .environmentObject(scoreModel)
        }
    }
}

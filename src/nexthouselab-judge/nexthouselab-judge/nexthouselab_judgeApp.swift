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
    @StateObject var messageHandler = MessageHandler()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(socketManager)
                .environmentObject(scoreModel)
                .environmentObject(messageHandler)
                .onAppear {
                    messageHandler.configure(socketManager: socketManager, scoreModel: scoreModel)
                }
        }
    }
}

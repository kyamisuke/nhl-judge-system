//
//  nexthouselab_judgeApp.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/06.
//

import SwiftUI

@main
struct nexthouselab_judgeApp: App {
    @StateObject var peerManager = PeerManager()
    @StateObject var scoreModel = ScoreModel()
    @StateObject var messageHandler = MessageHandler()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(peerManager)
                .environmentObject(scoreModel)
                .environmentObject(messageHandler)
                .onAppear {
                    messageHandler.configure(peerManager: peerManager, scoreModel: scoreModel)
                }
        }
    }
}

//
//  nexthouselab_hostApp.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI

@main
struct nexthouselab_hostApp: App {
    @StateObject var peerManager = PeerManager()
    @StateObject var scoreModel = ScoreModel()
    @StateObject var messageHandler = MessageHandler()
    @StateObject var judgePeerModel = JudgePeerModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(peerManager)
                .environmentObject(scoreModel)
                .environmentObject(messageHandler)
                .environmentObject(judgePeerModel)
                .onAppear {
                    // MessageHandlerに依存関係を設定
                    messageHandler.configure(peerManager: peerManager, scoreModel: scoreModel)
                    // PeerManagerにJudgePeerModelを設定
                    peerManager.judgePeerModel = judgePeerModel
                }
        }
    }
}

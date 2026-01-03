//
//  MessageHandler.swift
//  nexthouselab-judge
//
//  ネットワークメッセージの処理を担当するクラス
//

import Foundation
import SwiftUI

/// ネットワークメッセージを処理し、適切なモデルを更新するクラス
final class MessageHandler: ObservableObject {

    private weak var peerManager: PeerManager?
    private weak var scoreModel: ScoreModel?

    @Published var currentNumber: Int = 1

    init(peerManager: PeerManager? = nil, scoreModel: ScoreModel? = nil) {
        self.peerManager = peerManager
        self.scoreModel = scoreModel
    }

    /// PeerManagerとScoreModelへの参照を設定
    func configure(peerManager: PeerManager, scoreModel: ScoreModel) {
        self.peerManager = peerManager
        self.scoreModel = scoreModel
    }

    /// 受信したメッセージを処理する
    /// - Parameter rawMessage: スラッシュ区切りの文字列メッセージ
    /// - Returns: 処理が成功した場合はtrue
    @discardableResult
    func handleMessage(_ rawMessage: String) -> Bool {
        guard let message = NetworkMessage.parse(from: rawMessage) else {
            print("⚠️ Failed to parse message: \(rawMessage)")
            return false
        }

        return handleNetworkMessage(message)
    }

    /// 型安全なNetworkMessageを処理する
    private func handleNetworkMessage(_ message: NetworkMessage) -> Bool {
        switch message {
        case .currentNumber(let number):
            handleCurrentNumber(number)
            return true

        case .requestUpdate:
            handleUpdateRequest()
            return true

        case .editing, .decision, .cancel, .update:
            // 審査員側では受信しないメッセージ
            print("ℹ️ Received unexpected message type: \(message)")
            return true
        }
    }

    // MARK: - Individual Message Handlers

    /// 現在のプレイ番号を更新
    private func handleCurrentNumber(_ number: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.currentNumber = number
            print("🔢 Current Number: \(number)")
        }
    }

    /// ホストからのUPDATEリクエストに応答
    private func handleUpdateRequest() {
        guard let peerManager = peerManager,
              let scoreModel = scoreModel else {
            print("⚠️ PeerManager or ScoreModel not configured")
            return
        }

        guard let judgeName = UserDefaults.standard.string(forKey: AppConfiguration.StorageKeys.judgeName) else {
            print("⚠️ Judge name not found")
            return
        }

        do {
            // スコアと完了状態をJSON化して送信
            let scoresJson = try JSONSerialization.data(withJSONObject: scoreModel.scores)
            let scoresJsonStr = String(bytes: scoresJson, encoding: .utf8)!

            let doneStateJson = try JSONSerialization.data(withJSONObject: scoreModel.doneArray)
            let doneStateJsonStr = String(bytes: doneStateJson, encoding: .utf8)!

            let message = NetworkMessage.update(
                judgeName: judgeName,
                scores: scoreModel.scores,
                doneStates: scoreModel.doneArray
            )

            peerManager.send(message: message)
            print("🔄 Sent UPDATE response for \(judgeName)")
        } catch {
            print("❌ Failed to send UPDATE response: \(error)")
        }
    }

    /// メッセージを送信（型安全な送信ヘルパー）
    func sendMessage(_ message: NetworkMessage) {
        peerManager?.send(message: message)
    }
}

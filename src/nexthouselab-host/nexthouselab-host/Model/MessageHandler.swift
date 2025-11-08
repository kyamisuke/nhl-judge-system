//
//  MessageHandler.swift
//  nexthouselab-host
//
//  ネットワークメッセージの処理を担当するクラス
//

import Foundation
import SwiftUI

/// ネットワークメッセージを処理し、適切なモデルを更新するクラス
final class MessageHandler: ObservableObject {

    private weak var socketManager: SocketManager?
    private weak var scoreModel: ScoreModel?

    @Published var currentMessage: Message = Message(judgeName: "", number: 0)
    @Published var currentNumber: Int = 1

    init(socketManager: SocketManager? = nil, scoreModel: ScoreModel? = nil) {
        self.socketManager = socketManager
        self.scoreModel = scoreModel
    }

    /// SocketManagerとScoreModelへの参照を設定
    func configure(socketManager: SocketManager, scoreModel: ScoreModel) {
        self.socketManager = socketManager
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
        case .editing(let judgeName, let entryNumber):
            handleEditing(judgeName: judgeName, entryNumber: entryNumber)
            return true

        case .connect(let ipAddress):
            handleConnect(ipAddress: ipAddress)
            return true

        case .disconnect(let ipAddress):
            handleDisconnect(ipAddress: ipAddress)
            return true

        case .scorer(let judgeName, let entryNumber, let score):
            handleScorer(judgeName: judgeName, entryNumber: entryNumber, score: score)
            return true

        case .update(let judgeName, let scores):
            handleUpdate(judgeName: judgeName, scores: scores)
            return true

        case .currentNumber(let number):
            handleCurrentNumber(number)
            return true

        case .requestUpdate:
            // UPDATEリクエストは通常送信側でのみ使用
            return true
        }
    }

    // MARK: - Individual Message Handlers

    private func handleEditing(judgeName: String, entryNumber: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.currentMessage = Message(judgeName: judgeName, number: entryNumber)
            print("📝 Editing: \(judgeName) -> Entry #\(entryNumber)")
        }
    }

    private func handleConnect(ipAddress: String) {
        guard let socketManager = socketManager else { return }
        socketManager.connect(host: ipAddress)
        print("🔗 Connect: \(ipAddress)")
    }

    private func handleDisconnect(ipAddress: String) {
        guard let socketManager = socketManager else { return }
        socketManager.disconnect(host: ipAddress)
        print("🔌 Disconnect: \(ipAddress)")
    }

    private func handleScorer(judgeName: String, entryNumber: String, score: Float?) {
        guard let scoreModel = scoreModel else { return }
        DispatchQueue.main.async {
            scoreModel.scores[judgeName]?[entryNumber] = score
            let scoreText = score.map { String($0) } ?? "nil"
            print("⭐ Score Update: \(judgeName) -> Entry #\(entryNumber) = \(scoreText)")
        }
    }

    private func handleUpdate(judgeName: String, scores: [String: Float?]) {
        guard let scoreModel = scoreModel else { return }
        DispatchQueue.main.async {
            scoreModel.updateOptional(forKey: judgeName, scores: scores)
            print("🔄 Bulk Update: \(judgeName) - \(scores.count) entries updated")
        }
    }

    private func handleCurrentNumber(_ number: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.currentNumber = number
            print("🔢 Current Number: \(number)")
        }
    }
}

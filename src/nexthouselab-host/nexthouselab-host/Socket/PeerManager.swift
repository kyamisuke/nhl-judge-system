//
//  PeerManager.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2025/10/25.
//

import Foundation
import MultipeerConnectivity
import SwiftUI

/// ピア情報を管理する構造体
struct PeerInfo {
    let peerID: MCPeerID
    let judgeName: String
    let connectedAt: Date

    init(peerID: MCPeerID, judgeName: String) {
        self.peerID = peerID
        self.judgeName = judgeName
        self.connectedAt = Date()
    }
}

final class PeerManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var connectedPeers: [MCPeerID: PeerInfo] = [:]
    @Published var receivedData: String = ""
    @Published var connectionStatus: String = "未接続"
    @Published var stateColor: Color = .red
    @Published var isHosting: Bool = false

    // MARK: - Private Properties
    private let serviceType = "judge-session"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?

    // MARK: - Public Properties
    /// 審査員ピアのマッピングを管理するモデル（外部から設定）
    var judgePeerModel: JudgePeerModel?

    // MARK: - Private Properties
    private var isInitialized = false

    // MARK: - Init
    override init() {
        super.init()
        // 最大8台まで接続可能に設定（デフォルトは8だが明示的に指定）
        session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session.delegate = self
    }

    // MARK: - Start Hosting (ホスト側)
    func startHosting() {
        print("🔄 [startHosting] 開始")
        print("🔄 [startHosting] isInitialized: \(isInitialized)")

        // 既に初期化済みの場合はスキップ
        if isInitialized {
            print("⚠️ [startHosting] 既に初期化済みです。スキップします")
            return
        }

        // 既存のアドバタイザがあれば停止
        advertiser?.stopAdvertisingPeer()
        advertiser = nil

        // 初回のみセッションをクリーン
        if !isInitialized {
            session.disconnect()
            connectedPeers.removeAll()
        }

        // 新しいアドバタイザを作成
        let discoveryInfo = ["role": "host", "name": UIDevice.current.name]
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: discoveryInfo, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isHosting = true
        connectionStatus = "ホスト待機中"
        stateColor = .yellow
        isInitialized = true
        print("🟡 ホストとして待機を開始しました")
        print("🔄 [startHosting] アドバタイザを初期化しました")
    }

    // MARK: - Send Messages

    /// NetworkMessageを全ピアにブロードキャスト
    func send(message: NetworkMessage) {
        let messageString = message.serialize()
        guard !messageString.isEmpty else {
            print("❌ メッセージのシリアライズに失敗しました")
            return
        }
        send(messageString: messageString)
    }

    /// 文字列メッセージを全ピアにブロードキャスト
    func send(messageString: String) {
        guard !session.connectedPeers.isEmpty else {
            print("⚠️ 接続されているピアがありません")
            return
        }

        guard let data = messageString.data(using: .utf8) else {
            print("❌ メッセージのエンコードに失敗しました")
            return
        }

        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            print("✅ ブロードキャスト送信: \(messageString)")
        } catch {
            print("❌ ブロードキャスト送信失敗: \(error.localizedDescription)")
        }
    }

    /// 特定のピアにNetworkMessageを送信
    func send(to peerID: MCPeerID, message: NetworkMessage) {
        let messageString = message.serialize()
        guard !messageString.isEmpty else {
            print("❌ メッセージのシリアライズに失敗しました")
            return
        }
        send(to: peerID, messageString: messageString)
    }

    /// 特定のピアに文字列メッセージを送信
    func send(to peerID: MCPeerID, messageString: String) {
        guard session.connectedPeers.contains(peerID) else {
            print("⚠️ ピア \(peerID.displayName) は接続されていません")
            return
        }

        guard let data = messageString.data(using: .utf8) else {
            print("❌ メッセージのエンコードに失敗しました")
            return
        }

        do {
            try session.send(data, toPeers: [peerID], with: .reliable)
            print("✅ 送信完了 to \(peerID.displayName): \(messageString)")
        } catch {
            print("❌ 送信失敗 to \(peerID.displayName): \(error.localizedDescription)")
        }
    }

    // MARK: - Disconnect
    func disconnect() {
        advertiser?.stopAdvertisingPeer()
        session.disconnect()
        connectedPeers.removeAll()
        isHosting = false
        connectionStatus = "未接続"
        stateColor = .red
        print("🔴 ホストを停止しました")
    }

    // MARK: - Helper Methods

    /// 審査員名が既に接続されているかチェック
    private func isJudgeNameAlreadyConnected(_ judgeName: String) -> Bool {
        return connectedPeers.values.contains { $0.judgeName == judgeName }
    }
}

// MARK: - MCSessionDelegate
extension PeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("🔄 [Host:セッション状態変化] Peer: \(peerID.displayName), State: \(state.rawValue)")
        print("🔄 [Host:セッション状態変化] MCSession.connectedPeers: \(session.connectedPeers.map { $0.displayName })")

        DispatchQueue.main.async {
            switch state {
            case .connected:
                let peerInfo = self.connectedPeers[peerID]
                let judgeName = peerInfo?.judgeName ?? peerID.displayName
                self.connectionStatus = "接続済み (\(judgeName))"
                self.stateColor = .green
                print("🟢 [Host:接続完了] 審査員: \(judgeName)")
                print("🟢 [Host:接続完了] 現在の接続数: \(self.connectedPeers.count)")
                print("🟢 [Host:接続完了] MCSession接続ピア数: \(session.connectedPeers.count)")

            case .connecting:
                self.connectionStatus = "接続中 (\(peerID.displayName))"
                self.stateColor = .yellow
                print("🟡 [Host:接続中] Peer: \(peerID.displayName)")

            case .notConnected:
                if let peerInfo = self.connectedPeers[peerID] {
                    self.connectionStatus = "切断 (\(peerInfo.judgeName))"
                    print("🔴 [Host:切断] 審査員: \(peerInfo.judgeName)")
                    self.connectedPeers.removeValue(forKey: peerID)
                    // JudgePeerModelからも削除
                    self.judgePeerModel?.remove(peerID: peerID)
                } else {
                    self.connectionStatus = "切断 (\(peerID.displayName))"
                    print("🔴 [Host:切断] Peer: \(peerID.displayName)")
                }
                self.stateColor = .red

                // 接続しているピアの数に応じて状態を更新
                if !self.connectedPeers.isEmpty {
                    let count = self.connectedPeers.count
                    self.connectionStatus = "接続中 (\(count)名)"
                    self.stateColor = .green
                }

            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = String(data: data, encoding: .utf8) else {
            print("❌ メッセージのデコードに失敗しました")
            return
        }

        let judgeName = self.connectedPeers[peerID]?.judgeName ?? peerID.displayName
        print("📩 [受信] from \(judgeName) (peerID: \(peerID.displayName)): \(message)")

        DispatchQueue.main.async {
            // UUIDを付加して重複を防ぐ（SocketManagerと同様のパターン）
            let uuid = UUID().uuidString
            let messageWithUUID = "\(message)/\(uuid)"

            print("📝 [処理開始] \(judgeName): \(messageWithUUID)")
            self.receivedData = messageWithUUID
            print("✅ [receivedData更新] 現在値: \(self.receivedData)")
        }
    }

    // 未使用だが必須メソッド
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Advertiser Delegate
extension PeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📡 招待リクエスト from \(peerID.displayName)")

        // contextから審査員名を取得
        var judgeName = peerID.displayName
        if let context = context,
           let contextString = String(data: context, encoding: .utf8) {
            judgeName = contextString
            print("👤 審査員名: \(judgeName)")
        }

        // 現在の接続状況をログ出力
        print("📊 現在の接続数: \(connectedPeers.count)")
        print("📊 接続中の審査員: \(connectedPeers.values.map { $0.judgeName }.joined(separator: ", "))")

        // 審査員名の重複チェック
        if isJudgeNameAlreadyConnected(judgeName) {
            print("❌ 拒否: 審査員名 '\(judgeName)' は既に接続されています")
            invitationHandler(false, nil)
            return
        }

        // 接続を承認し、ピア情報を保存
        print("✅ 承認: \(judgeName) - 接続を許可します")
        let peerInfo = PeerInfo(peerID: peerID, judgeName: judgeName)
        DispatchQueue.main.async {
            self.connectedPeers[peerID] = peerInfo
            // JudgePeerModelにも登録
            let registered = self.judgePeerModel?.register(peerID: peerID, judgeName: judgeName)
            print("📝 JudgePeerModelに登録: \(registered == true ? "成功" : "失敗")")
        }
        invitationHandler(true, session)
    }
}

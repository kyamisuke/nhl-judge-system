//
//  PeerManager.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2025/11/08.
//

import Foundation
import MultipeerConnectivity
import SwiftUI

/// ホストピア情報を管理する構造体
struct HostPeerInfo: Equatable {
    let peerID: MCPeerID
    let hostName: String
    let discoveredAt: Date

    init(peerID: MCPeerID, hostName: String) {
        self.peerID = peerID
        self.hostName = hostName
        self.discoveredAt = Date()
    }

    // Equatable準拠: peerIDで比較
    static func == (lhs: HostPeerInfo, rhs: HostPeerInfo) -> Bool {
        return lhs.peerID == rhs.peerID
    }
}

final class PeerManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var availableHosts: [MCPeerID: HostPeerInfo] = [:]
    @Published var connectedHost: MCPeerID?
    @Published var receivedData: String = ""
    @Published var connectionStatus: String = "未接続"
    @Published var stateColor: Color = .red

    // MARK: - Private Properties
    private let serviceType = "judge-session"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession!
    private var browser: MCNearbyServiceBrowser?
    private var judgeName: String = ""

    // MARK: - Private Properties
    private var isInitialized = false

    // MARK: - Init
    override init() {
        super.init()
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }

    // MARK: - Start Browsing (審査員側)
    func startBrowsing(judgeName: String) {
        print("🔄 [startBrowsing] 開始 - 審査員名: \(judgeName)")
        print("🔄 [startBrowsing] isInitialized: \(isInitialized)")

        // 審査員名を先に保存
        self.judgeName = judgeName

        // 既に初期化済みの場合はスキップ
        if isInitialized {
            print("⚠️ [startBrowsing] 既に初期化済みです。スキップします")
            return
        }

        // 既存のブラウザがあれば停止
        browser?.stopBrowsingForPeers()
        browser = nil

        // 初回のみセッションをクリーン
        if !isInitialized {
            session.disconnect()
            connectedHost = nil
            availableHosts.removeAll()
        }

        // 新しいブラウザを作成
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        connectionStatus = "ホストを検索中"
        stateColor = .yellow
        isInitialized = true
        print("🟡 ホストの検索を開始しました (審査員: \(self.judgeName))")
        print("🔄 [startBrowsing] ブラウザを初期化しました")
    }

    // MARK: - Connect to Host
    func connect(to hostPeerID: MCPeerID) {
        guard let browser = browser else {
            print("⚠️ ブラウザが起動していません")
            return
        }

        // 審査員名をcontextとして送信
        let context = judgeName.data(using: .utf8)
        browser.invitePeer(hostPeerID, to: session, withContext: context, timeout: 30)
        connectionStatus = "接続中..."
        stateColor = .yellow
        print("🟡 ホストに接続リクエスト送信: \(hostPeerID.displayName)")
    }

    // MARK: - Send Messages

    /// NetworkMessageをホストに送信
    func send(message: NetworkMessage) {
        let messageString = message.serialize()
        guard !messageString.isEmpty else {
            print("❌ メッセージのシリアライズに失敗しました")
            return
        }
        send(messageString: messageString)
    }

    /// 文字列メッセージをホストに送信
    func send(messageString: String) {
        print("📤 [送信開始] メッセージ: \(messageString)")
        print("📤 [送信開始] 審査員名: \(judgeName)")

        guard let hostPeer = connectedHost else {
            print("⚠️ ホストに接続されていません")
            return
        }
        print("📤 [送信開始] ホストPeerID: \(hostPeer.displayName)")

        let connectedPeersList = session.connectedPeers.map { $0.displayName }.joined(separator: ", ")
        print("📤 [送信開始] 接続中のピア: [\(connectedPeersList)]")
        print("📤 [送信開始] 接続ピア数: \(session.connectedPeers.count)")

        guard session.connectedPeers.contains(hostPeer) else {
            print("⚠️ ホストとの接続が切れています")
            print("⚠️ connectedHost: \(hostPeer.displayName)")
            print("⚠️ session.connectedPeers: \(connectedPeersList)")
            connectedHost = nil
            connectionStatus = "未接続"
            stateColor = .red
            return
        }

        guard let data = messageString.data(using: .utf8) else {
            print("❌ メッセージのエンコードに失敗しました")
            return
        }

        do {
            try session.send(data, toPeers: [hostPeer], with: .reliable)
            print("✅ [送信成功] to \(hostPeer.displayName): \(messageString)")
        } catch {
            print("❌ [送信失敗] to \(hostPeer.displayName): \(error.localizedDescription)")
        }
    }

    // MARK: - Disconnect
    func disconnect() {
        browser?.stopBrowsingForPeers()
        session.disconnect()
        connectedHost = nil
        availableHosts.removeAll()
        connectionStatus = "未接続"
        stateColor = .red
        print("🔴 接続を切断しました")
    }
}

// MARK: - MCSessionDelegate
extension PeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("🔄 [セッション状態変化] Peer: \(peerID.displayName), State: \(state.rawValue)")
        print("🔄 [セッション状態変化] 審査員名: \(self.judgeName)")

        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedHost = peerID
                let hostName = self.availableHosts[peerID]?.hostName ?? peerID.displayName
                self.connectionStatus = "接続済み (\(hostName))"
                self.stateColor = .green
                print("🟢 [接続完了] ホスト: \(hostName), 審査員名: \(self.judgeName)")
                print("🟢 [接続完了] MCSession.connectedPeers: \(session.connectedPeers.map { $0.displayName })")

            case .connecting:
                self.connectionStatus = "接続中 (\(peerID.displayName))"
                self.stateColor = .yellow
                print("🟡 [接続中] ホスト: \(peerID.displayName)")

            case .notConnected:
                if self.connectedHost == peerID {
                    self.connectedHost = nil
                    let hostName = self.availableHosts[peerID]?.hostName ?? peerID.displayName
                    self.connectionStatus = "切断 (\(hostName))"
                    print("🔴 [切断] ホスト: \(hostName)")
                }
                self.stateColor = .red

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

        DispatchQueue.main.async {
            // SocketManagerと同様に、単にreceivedDataを更新
            self.receivedData = message

            let hostName = self.availableHosts[peerID]?.hostName ?? peerID.displayName
            print("📩 受信 from \(hostName): \(message)")
        }
    }

    // 未使用だが必須メソッド
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Browser Delegate
extension PeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // discoveryInfoからホスト情報を取得
        let role = info?["role"] ?? "unknown"
        let hostName = info?["name"] ?? peerID.displayName

        // ホストのみを対象とする
        guard role == "host" else {
            print("⚠️ スキップ: ホストではないピア \(peerID.displayName)")
            return
        }

        print("🔍 ホスト発見: \(hostName)")

        DispatchQueue.main.async {
            let hostInfo = HostPeerInfo(peerID: peerID, hostName: hostName)
            self.availableHosts[peerID] = hostInfo
        }

        // 自動接続はせず、ユーザーが選択するまで待機
        // 必要に応じてconnect(to:)を呼び出す
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if let hostInfo = self.availableHosts[peerID] {
                print("❌ ホスト喪失: \(hostInfo.hostName)")
                self.availableHosts.removeValue(forKey: peerID)
            }
        }
    }
}

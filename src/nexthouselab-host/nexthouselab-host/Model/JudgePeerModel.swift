//
//  JudgePeerModel.swift
//  nexthouselab-host
//
//  ピアIDと審査員名のマッピングを管理するモデル
//

import Foundation
import MultipeerConnectivity
import Combine

/// MultipeerConnectivityで接続された審査員のピアIDと名前を管理するクラス
final class JudgePeerModel: ObservableObject {

    // MARK: - Published Properties

    /// ピアIDから審査員名へのマッピング
    @Published var peerToJudge: [MCPeerID: String] = [:]

    /// 審査員名からピアIDへのマッピング
    @Published var judgeToPeer: [String: MCPeerID] = [:]

    // MARK: - Public Methods

    /// 新しい審査員を登録する
    /// - Parameters:
    ///   - peerID: MultipeerConnectivityのピアID
    ///   - judgeName: 審査員の名前
    /// - Returns: 登録が成功した場合はtrue、重複などで失敗した場合はfalse
    @discardableResult
    func register(peerID: MCPeerID, judgeName: String) -> Bool {
        // 既に同じ審査員名が登録されているかチェック
        if let existingPeerID = judgeToPeer[judgeName], existingPeerID != peerID {
            print("⚠️ 審査員名 '\(judgeName)' は既に別のピアで登録されています")
            return false
        }

        // 既に同じピアIDが登録されているかチェック
        if let existingName = peerToJudge[peerID], existingName != judgeName {
            print("⚠️ ピアID \(peerID.displayName) は既に '\(existingName)' として登録されています")
            // 既存の登録を更新
            remove(peerID: peerID)
        }

        // 双方向マッピングに登録
        peerToJudge[peerID] = judgeName
        judgeToPeer[judgeName] = peerID

        print("✅ 審査員登録: \(judgeName) ↔ \(peerID.displayName)")
        return true
    }

    /// 審査員の登録を削除する
    /// - Parameter peerID: 削除するピアID
    func remove(peerID: MCPeerID) {
        guard let judgeName = peerToJudge[peerID] else {
            print("⚠️ ピアID \(peerID.displayName) は登録されていません")
            return
        }

        peerToJudge.removeValue(forKey: peerID)
        judgeToPeer.removeValue(forKey: judgeName)

        print("🗑️ 審査員削除: \(judgeName) ↔ \(peerID.displayName)")
    }

    /// 審査員名から対応するピアIDを取得する
    /// - Parameter judgeName: 審査員の名前
    /// - Returns: 対応するピアID。見つからない場合はnil
    func getPeerID(forJudge judgeName: String) -> MCPeerID? {
        return judgeToPeer[judgeName]
    }

    /// ピアIDから対応する審査員名を取得する
    /// - Parameter peerID: ピアID
    /// - Returns: 対応する審査員名。見つからない場合はnil
    func getJudgeName(forPeer peerID: MCPeerID) -> String? {
        return peerToJudge[peerID]
    }

    /// 登録されている審査員の数を取得する
    var count: Int {
        return peerToJudge.count
    }

    /// 登録されている全ての審査員名を取得する
    var allJudgeNames: [String] {
        return Array(judgeToPeer.keys).sorted()
    }

    /// 登録されている全てのピアIDを取得する
    var allPeerIDs: [MCPeerID] {
        return Array(peerToJudge.keys)
    }

    /// 全ての登録をクリアする
    func clearAll() {
        peerToJudge.removeAll()
        judgeToPeer.removeAll()
        print("🗑️ 全ての審査員登録をクリアしました")
    }
}

//
//  SelectHostView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/06/08.
//

import SwiftUI

struct SelectHostView: View {
    @EnvironmentObject var peerManager: PeerManager

    var body: some View {
        VStack(spacing: 16) {
            // 接続状態サマリー（シンプル）
            HStack {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 12, height: 12)
                Text(connectionStatusText)
                    .foregroundStyle(connectionStatusColor)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // 説明テキスト
            VStack(spacing: 8) {
                if peerManager.connectedHost == nil {
                    Text("ホストを自動検索中...")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    Text("ホストに接続しました")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // 審査員名を取得してブラウジング開始
            if let judgeName = UserDefaults.standard.string(forKey: AppConfiguration.StorageKeys.judgeName) {
                print("🔍 [SelectHostView] 取得した審査員名: \(judgeName)")
                peerManager.startBrowsing(judgeName: judgeName)
                print("🔍 [SelectHostView] ブラウジング開始: \(judgeName)")
            } else {
                print("⚠️ [SelectHostView] 審査員名が取得できません")
            }
            // もし未接続なら自動接続を試みる
            attemptAutoConnect()
        }
        .onChange(of: peerManager.availableHosts) {
            // ホストが見つかったら自動接続
            attemptAutoConnect()
        }
    }

    // 接続状態に応じた色
    private var connectionStatusColor: Color {
        if peerManager.connectedHost != nil {
            return .green
        } else if !peerManager.availableHosts.isEmpty {
            return .yellow
        } else {
            return .red
        }
    }

    // 接続状態テキスト
    private var connectionStatusText: String {
        if let connectedHost = peerManager.connectedHost {
            return "接続中: \(connectedHost.displayName)"
        } else if !peerManager.availableHosts.isEmpty {
            return "ホスト検出中..."
        } else {
            return "ホスト未検出"
        }
    }

    // 自動接続を試みる
    private func attemptAutoConnect() {
        print("🔍 [attemptAutoConnect] 開始")
        print("🔍 [attemptAutoConnect] connectedHost: \(peerManager.connectedHost?.displayName ?? "nil")")
        print("🔍 [attemptAutoConnect] availableHosts数: \(peerManager.availableHosts.count)")

        // 既に接続している場合は何もしない
        guard peerManager.connectedHost == nil else {
            print("🔍 [attemptAutoConnect] 既に接続済みのため終了")
            return
        }

        // 利用可能なホストがあれば最初のものに接続
        if let firstHost = peerManager.availableHosts.keys.first {
            print("🔵 [attemptAutoConnect] 自動接続開始: \(firstHost.displayName)")
            peerManager.connect(to: firstHost)
        } else {
            print("🔍 [attemptAutoConnect] 利用可能なホストがありません")
        }
    }
}

#Preview {
    struct Sim: View {
        @StateObject var peerManager = PeerManager()

        var body: some View {
            SelectHostView()
                .environmentObject(peerManager)
        }
    }

    return Sim()
}

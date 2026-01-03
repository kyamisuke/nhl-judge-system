//
//  HostSelectModalView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/06/08.
//

import SwiftUI
import MultipeerConnectivity

struct HostSelectModalView: View {
    @Binding var isModal: Bool
    @EnvironmentObject var peerManager: PeerManager
    @EnvironmentObject var judgePeerModel: JudgePeerModel

    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー（閉じるボタン）
            HStack {
                Text("接続中の審査員を管理")
                    .font(.headline)
                Spacer()
                Button(action: {
                    isModal = false
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                })
            }
            .padding()

            // 接続状態サマリー（シンプル）
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("接続中: \(judgePeerModel.count)名")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(connectionStatusText)
                        .font(.caption)
                        .foregroundStyle(connectionStatusColor)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)

            // 接続済み審査員リスト（表示のみ）
            List {
                Section(header: Text("接続済み審査員")) {
                    if judgePeerModel.count == 0 {
                        HStack {
                            Spacer()
                            Text("接続している審査員はいません")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    } else {
                        ForEach(judgePeerModel.allJudgeNames.sorted(), id: \.self) { judgeName in
                            HStack {
                                // 接続状態インジケーター
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)

                                Spacer()

                                // 審査員名
                                Text(judgeName)
                                    .fontWeight(.bold)

                                Spacer()

                                // 接続中表示
                                Text("接続中")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .padding(.horizontal)

            // 説明テキスト
            Text("審査員アプリから自動的に接続されます")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
    }

    // 接続状態に応じた色
    private var connectionStatusColor: Color {
        if peerManager.isHosting {
            return .green
        } else {
            return .red
        }
    }

    // 接続状態テキスト
    private var connectionStatusText: String {
        if peerManager.isHosting {
            return "ホスティング中"
        } else {
            return "停止中"
        }
    }
}

#Preview {
    struct Sim: View {
        @StateObject var peerManager = PeerManager()
        @StateObject var judgePeerModel = JudgePeerModel()

        var body: some View {
            HostSelectModalView(isModal: .constant(true))
                .environmentObject(peerManager)
                .environmentObject(judgePeerModel)
                .onAppear {
                    peerManager.judgePeerModel = judgePeerModel
                }
        }
    }

    return Sim()
}

//
//  PhoneMainView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/06/06.
//

import SwiftUI
import Network

struct PhoneMainView: View {
    // リストに表示するものたち
    @State var entryMembers = [EntryName(number: 1, name: "kyami"), EntryName(number: 2, name: "amazon"), EntryName(number: 3, name: "Amazon")]
    @State var currentNumber: Int = 1
    @State var judgeArray = [JudgeName]()
    
    // スクロール同期に関わる部分
    @State var offset: CGFloat = 0
    @State var ges = "ges"
    @State var dragDistance: CGFloat = 0
    @State var preDragPosition: CGFloat = 0
    @State var isFirstDrag = true
    @State var onClearAction = false

    @EnvironmentObject var peerManager: PeerManager
    @EnvironmentObject var scoreModel: ScoreModel
    @EnvironmentObject var messageHandler: MessageHandler

    @State var currentMessage = Message(judgeName: "", number: 0)
    
    var body: some View {
        NavigationStack {
            VStack {
                // 各ジャッジのリストを表示
                JudgeView(entryMembers: $entryMembers, offset: $offset, currentNumber: $messageHandler.currentNumber, currentMessage: $messageHandler.currentMessage, isModal: .constant(false), mode: .constant(Const.Mode.dual))
                    .onChange(of: peerManager.receivedData) {
                        messageHandler.handleMessage(peerManager.receivedData)
                    }
//                Group {
//                    Button(action: {
//                        if self.currentNumber != 1 {
//                            currentNumber -= 2
//                        }
//                    }, label: {
//                        Image(systemName: "arrowtriangle.up.fill")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(maxWidth: .infinity)
//                            .frame(height: 24)
//                            .padding(.vertical, 4)
//                    })
//                    .buttonStyle(.custom)
//                    .disabled(currentNumber == 1)
//                    Button(action: {
//                        if self.currentNumber + 2 <= entryMembers.count {
//                            currentNumber += 2
//                        }
//                    }, label: {
//                        Image(systemName: "arrowtriangle.down.fill")
//                            .resizable()
//                            .aspectRatio(contentMode: .fit)
//                            .frame(maxWidth: .infinity)
//                            .frame(height: 24)
//                            .padding(.vertical, 4)
//                    })
//                    .buttonStyle(.custom)
//                    .disabled(currentNumber + 2 > entryMembers.count)
//                }
//                .padding(.horizontal, 8)
//                .onChange(of: currentNumber) {
//                    socketManager.send(message: String(currentNumber))
//                }
//                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PrincipalIcon(entryMembers: entryMembers, onClearAction: $onClearAction)
                }
            }
            .onAppear {
                scoreModel.startTimer()
                scoreModel.initialize(entryNames: entryMembers)
                // MultipeerConnectivityでホストとして起動
                peerManager.startHosting()
                print("🟢 Phone mode: PeerManager started as host")
            }
            .onDisappear {
                scoreModel.stopTimer()
            }
            .alert(isPresented: $onClearAction) {
                Alert(
                    title: Text("現在のデータをリセットします。"),
                    message: Text("本当にリセットしますか？（データの復元はできません）"),
                    primaryButton: .default(Text("リセット"), action: {
                        UserDefaults.standard.setValue(nil, forKey: Const.SCORES_KEY)
                        scoreModel.initialize(entryNames: entryMembers)
                        onClearAction = false
                    }),
                    secondaryButton: .cancel(Text("キャンセル"), action: {
                        onClearAction = false
                    })
                )
            }
        }
    }
    // receiveMessage関数は削除（MessageHandlerに委譲）
}

#Preview {
    struct Sim: View {
        @StateObject var peerManager = PeerManager()
        @StateObject var scoreModel = ScoreModel()
        @StateObject var messageHandler = MessageHandler()

        var body: some View {
            PhoneMainView()
                .environmentObject(peerManager)
                .environmentObject(scoreModel)
                .environmentObject(messageHandler)
                .onAppear {
                    messageHandler.configure(peerManager: peerManager, scoreModel: scoreModel)
                }
        }
    }
    return Sim()
}

//
//  MainView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI
import Network

struct MainView: View {
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
    @State var isTapped = false
    @State var isModal = false

    @EnvironmentObject var peerManager: PeerManager
    @EnvironmentObject var scoreModel: ScoreModel
    @EnvironmentObject var messageHandler: MessageHandler

    @State var timer: Timer?
    
    // TODO: 決め打ちなので、UIから変更できるような仕組みを作る
    @State var currentMode = Const.Mode.dual
    
    let device = UIDevice.current
    
    var body: some View {
        NavigationStack {
            VStack {
                // 各ジャッジのリストを表示
                JudgeView(entryMembers: $entryMembers, offset: $offset, currentNumber: $messageHandler.currentNumber, currentMessage: $messageHandler.currentMessage, isModal: $isModal, mode: $currentMode)
                    .onChange(of: peerManager.receivedData) {
                        receiveMessage(message: peerManager.receivedData)
                    }
                if device.isiPad {
                    Group {
                        Button(action: {
                            if messageHandler.currentNumber != 1 {
                                messageHandler.currentNumber -= currentMode.playerNum()
                            }
                            isTapped = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isTapped = false
                            }
                        }, label: {
                            Image(systemName: "arrowtriangle.up.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 24)
                                .padding(.vertical, 4)
                        })
                        .buttonStyle(.custom)
                        .disabled(messageHandler.currentNumber == 1 || isTapped)
                        Button(action: {
                            if messageHandler.currentNumber + currentMode.playerNum() <= entryMembers.count {
                                messageHandler.currentNumber += currentMode.playerNum()
                            }
                            isTapped = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                isTapped = false
                            }
                        }, label: {
                            Image(systemName: "arrowtriangle.down.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 24)
                                .padding(.vertical, 4)
                        })
                        .buttonStyle(.custom)
                        .disabled(messageHandler.currentNumber + currentMode.playerNum() > entryMembers.count || isTapped)
                    }
                    .padding(.horizontal, 8)
                    .onChange(of: messageHandler.currentNumber) {
                        peerManager.send(messageString: String(messageHandler.currentNumber))
                    }
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PrincipalIcon(entryMembers: entryMembers, onClearAction: $onClearAction)
                }
            }
            .onAppear {
                scoreModelInit()
                peerManagerInit()
            }
            .onDisappear {
                scoreModel.stopTimer()
                timer?.invalidate()
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
            .sheet(isPresented: $isModal) {
                // MultipeerConnectivityでは接続済みのピア一覧を表示
                // TODO: ピア管理用のモーダルビューが必要
                Text("接続中のピア: \(peerManager.connectedPeers.count)名")
            }
        }
    }
    
    func receiveMessage(message: String) {
        print("🔍 [MainView] 受信メッセージ処理開始: \(message)")

        // PeerManagerではUUID付加を行っているため、UUID部分を除去してから処理
        let components = message.components(separatedBy: "/")

        // 最後のコンポーネント（UUID）を除去
        guard components.count >= 2 else {
            print("⚠️ [MainView] UUID付加されていないメッセージ: \(message)")
            messageHandler.handleMessage(message)
            return
        }

        // UUIDを除いた部分を再構築
        let messageWithoutUUID = components.dropLast().joined(separator: "/")
        print("🔍 [MainView] UUID除去後: \(messageWithoutUUID)")

        // MessageHandlerに処理を委譲
        messageHandler.handleMessage(messageWithoutUUID)
    }

    func scoreModelInit() {
        scoreModel.startTimer()
        scoreModel.initialize(entryNames: entryMembers)
    }

    func peerManagerInit() {
        // MultipeerConnectivityでホストとして起動
        peerManager.startHosting()
        print("🟢 PeerManager initialized as host")
    }
}

#Preview {
    struct Sim: View {
        @StateObject var peerManager = PeerManager()
        @StateObject var scoreModel = ScoreModel()
        @StateObject var messageHandler = MessageHandler()

        var body: some View {
            MainView()
                .environmentObject(peerManager)
                .environmentObject(scoreModel)
                .environmentObject(messageHandler)
        }
    }
    return Sim()
}

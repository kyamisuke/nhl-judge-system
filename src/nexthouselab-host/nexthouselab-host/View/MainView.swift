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

    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    @EnvironmentObject var messageHandler: MessageHandler
    @State var judgeIpModel: JudgeIpModel = JudgeIpModel()

    @State var timer: Timer?
    
    // TODO: 決め打ちなので、UIから変更できるような仕組みを作る
    @State var currentMode = Const.Mode.dual
    
    let device = UIDevice.current
    
    var body: some View {
        NavigationStack {
            VStack {
                // 各ジャッジのリストを表示
                JudgeView(entryMembers: $entryMembers, offset: $offset, currentNumber: $messageHandler.currentNumber, currentMessage: $messageHandler.currentMessage, isModal: $isModal, judgeIpModel: $judgeIpModel, mode: $currentMode)
                    .onChange(of: socketManager.receivedData) {
                        receiveMessage(message: socketManager.receivedData)
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
                        socketManager.send(message: String(messageHandler.currentNumber))
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
                socketManagerInit()
                startTimer()
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
                HostSelectModalView(isModal: $isModal, hostArray: $judgeIpModel)
            }
        }
    }
    
    func receiveMessage(message: String) {
        // MessageHandlerに処理を委譲
        messageHandler.handleMessage(message)

        // UUIDキーを削除（メッセージの最後のコンポーネント）
        let components = message.components(separatedBy: "/")
        if let uuidKey = components.last {
            socketManager.storedData.removeValue(forKey: uuidKey)
        }
    }
    
    func scoreModelInit() {
        scoreModel.startTimer()
        scoreModel.initialize(entryNames: entryMembers)
    }
    
    func socketManagerInit() {
        if device.isiPad {
            DispatchQueue.global(qos: .background).async {
                socketManager.startListener(name: "host-listener")
            }
            hostArrayInit()
        } else if device.isiPhone {
            DispatchQueue.global(qos: .background).async {
                socketManager.startListener(name: "host-9000-listener")
                socketManager.startListenerForPhone(name: "host-8000-listener")
            }
        }
    }
    
    func hostArrayInit() {
        guard let hosts = UserDefaults.standard.dictionary(forKey: Const.HOST_KEY) as? [String: String] else {
            return
        }
        socketManager.connectAllHosts(hosts: hosts.map{ $0.value })
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            if (socketManager.storedData.isEmpty) { return }
            for m in socketManager.storedData.values {
                print("restore: \(m)")
                self.receiveMessage(message: m)
            }
        }
    }
}

#Preview {
    struct Sim: View {
        @StateObject var socketManager = SocketManager()
        @StateObject var scoreModel = ScoreModel()
        
        var body: some View {
            MainView()
                .environmentObject(socketManager)
                .environmentObject(scoreModel)
        }
    }
    return Sim()
}

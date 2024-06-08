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
    @State var hostArray = [String]()

    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    
    @State var currentMessage = Message(judgeName: "", number: 0)
    
    let device = UIDevice.current
    
    var body: some View {
        //        Text(ges)
        NavigationStack {
            VStack {
                // 各ジャッジのリストを表示
                JudgeView(entryMembers: $entryMembers, offset: $offset, currentNumber: $currentNumber, currentMessage: $currentMessage, isModal: $isModal)
                    .onChange(of: socketManager.recievedData) {
                        receiveMessage(message: socketManager.recievedData)
                    }
                if device.isiPad {
                    Group {
                        Button(action: {
                            if self.currentNumber != 1 {
                                currentNumber -= 2
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
                        .disabled(currentNumber == 1 || isTapped)
                        Button(action: {
                            if self.currentNumber + 2 <= entryMembers.count {
                                currentNumber += 2
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
                        .disabled(currentNumber + 2 > entryMembers.count || isTapped)
                    }
                    .padding(.horizontal, 8)
                    .onChange(of: currentNumber) {
                        socketManager.send(message: String(currentNumber))
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
            .sheet(isPresented: $isModal) {
                HostSelectModalView(isModal: $isModal, hostArray: $hostArray)
            }
        }
    }
    
    func receiveMessage(message: String) {
        let data = message.components(separatedBy: "/")
        // 先頭にコマンドが入っているので其れによって処理分岐
        if data[0] == "EDITING" {
            // ${judgeName}が今操作している欄を取得
            guard let num = Int(data[2]) else { return }
            let name = data[1]
            currentMessage = Message(judgeName: name, number: num)
            print(currentMessage)
        }
        else if data[0] == "CONNECT" {
            // 接続開始したIPアドレスを取得
            socketManager.connect(host: data[1], port: "8000", param: .udp)
            print(data[1])
        } else if data[0] == "SCORER" {
            //            if data[1] == "DECISION" {
            scoreModel.scores[data[2]]![data[3]] = Float(data[4])!
            //            } else if data[1] == "CANCEL" {
            //                scoreModel.scores[data[2]]![data[3]] = Float(data[4])!
            //            }
        } else if data[0] == "DISCONNECT" {
            socketManager.disconnect(host: data[1])
        } else {
            guard let currentNum = Int(message) else {
                return
            }
            self.currentNumber = currentNum
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
        guard let hosts = UserDefaults.standard.array(forKey: Const.HOST_KEY) as? [String] else {
            return
        }
        hostArray = hosts
        socketManager.connectAllHosts(hosts: hosts, port: "8000", param: .udp)
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

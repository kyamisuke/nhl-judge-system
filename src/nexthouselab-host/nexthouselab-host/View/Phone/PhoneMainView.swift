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
    
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    
    @State var currentMessage = Message(judgeName: "", number: 0)
    
    var body: some View {
        NavigationStack {
            VStack {
                // 各ジャッジのリストを表示
                JudgeView(entryMembers: $entryMembers, offset: $offset, currentNumber: $currentNumber, currentMessage: $currentMessage)
                    .onChange(of: socketManager.recievedData) {
                        receiveMessage(message: socketManager.recievedData)
                    }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PrincipalIcon(entryMembers: entryMembers, onClearAction: $onClearAction)
                }
            }
            .onAppear {
                scoreModel.startTimer()
                scoreModel.initialize(entryNames: entryMembers)
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
            socketManager.ipAddresses.append(data[1])
            print(data[1])
        } else if data[0] == "SCORER" {
            //            if data[1] == "DECISION" {
            scoreModel.scores[data[2]]![data[3]] = Float(data[4])!
            //            } else if data[1] == "CANCEL" {
            //                scoreModel.scores[data[2]]![data[3]] = Float(data[4])!
            //            }
        }
    }
}

#Preview {
    struct Sim: View {
        @StateObject var socketManager = SocketManager()
        @StateObject var scoreModel = ScoreModel()
        
        var body: some View {
            PhoneMainView()
                .environmentObject(socketManager)
                .environmentObject(scoreModel)
        }
    }
    return Sim()
}

//
//  MainView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI
import Network

struct MainView: View {
    // ファイルIO
    @State var selectedFileContent: String = ""
    
    // リストに表示するものたち
    @State var entryMembers = [EntryName(number: 1, name: "kyami"), EntryName(number: 2, name: "amazon"), EntryName(number: 3, name: "Amazon")]
    @State var demoJudgeArrray = [JudgeName(name: "KAZANE"), JudgeName(name: "HIRO"), JudgeName(name: "YUU"), JudgeName(name: "KAZUKIYO")]
    @State var currentNumber: Int = 1
    @State var judgeArray = [JudgeName]()
    
    // スクロール同期に関わる部分
    @State var offset: CGFloat = 0
    @State var ges = "ges"
    @State var dragDistance: CGFloat = 0
    @State var preDragPosition: CGFloat = 0
    @State var isFirstDrag = true
    
    @EnvironmentObject var socketManager: SocketManager
    
    @State var currentMessage = Message(judgeName: "", number: 0)
                
    var body: some View {
//        Text(ges)
        ZStack {
            VStack {
                // 各ジャッジのリストを表示
                JudgeView(judgeNames: $demoJudgeArrray, entryMembers: $entryMembers, offset: $offset, currentNumber: $currentNumber, currentMessage: $currentMessage)
                    .onChange(of: socketManager.recievedData) {
                        receiveMessage(message: socketManager.recievedData)
                    }
                
                HStack {
                    Button(action: {
                        if self.currentNumber != 1 {
                            currentNumber -= 2
                        }
                    }, label: {
                        Text("前へ")
                    })
                    Button(action: {
                        if self.currentNumber + 2 <= entryMembers.count {
                            currentNumber += 2
                        }
                    }, label: {
                        Text("次へ")
                    })
                }
                .onChange(of: currentNumber) {
                    socketManager.send(message: String(currentNumber))
                }

                // ファイル選択ボタン
                FolderImportView(fileContent: $selectedFileContent)
                    .onChange(of: selectedFileContent, {
                        entryMembers = []
                        let contentArray = selectedFileContent.components(separatedBy: ",")
                        for (i, content) in contentArray.enumerated() {
                            entryMembers.append(EntryName(number: i, name: content))
                        }
                    })
                
                Button(action: {
                    socketManager.startListener(name: "host_listener")
                    socketManager.connect(host: "127.0.0.1", port: "8000", param: .udp)
                }, label: {
                    Text("通信待受開始")
                })
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
        }
    }
}

#Preview {
    struct Sim: View {
        @StateObject var socketManager = SocketManager()
        
        var body: some View {
            MainView()
                .environmentObject(socketManager)
        }
    }
    return Sim()
}
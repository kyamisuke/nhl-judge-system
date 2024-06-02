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
    @State var currentNumber: Int = 1
    @State var judgeArray = [JudgeName]()
    
    // スクロール同期に関わる部分
    @State var offset: CGFloat = 0
    @State var ges = "ges"
    @State var dragDistance: CGFloat = 0
    @State var preDragPosition: CGFloat = 0
    @State var isFirstDrag = true
    
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    
    @State var currentMessage = Message(judgeName: "", number: 0)
    @State var bloadcastIp = ""

    var body: some View {
//        Text(ges)
        NavigationStack {
            ZStack {
                VStack {
                    // 各ジャッジのリストを表示
                    JudgeView(entryMembers: $entryMembers, offset: $offset, currentNumber: $currentNumber, currentMessage: $currentMessage)
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
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            UserDefaults.standard.setValue(nil, forKey: "scores")
                            scoreModel.initialize(entryNames: entryMembers)
                        }, label: {
                            Text("Clear")
                        })
                        .buttonStyle(.custom)
                        .tint(.gray)
                        // ファイル選択ボタン
                        FolderImportView(fileContent: $selectedFileContent)
                            .onChange(of: selectedFileContent, {
                                entryMembers = []
                                let contentArray = selectedFileContent.components(separatedBy: "\n")
                                for content in contentArray {
                                    let data = content.components(separatedBy: ",")
                                    if data.count != 2 { return }
                                    entryMembers.append(EntryName(number: Int(data[0])!, name: data[1]))
                                }
                            })
                            .onAppear{
                                guard let data = UserDefaults.standard.string(forKey: Const.SELCTED_FILE_KEY) else { return }
                                selectedFileContent = data
                            }
                        FolderExportView()
                        PrincipalIcon()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        VStack(alignment: .leading) {
                            TextField(text: $bloadcastIp, label: {
                                Text("host ip")
                            })
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 150)
                            .onChange(of: bloadcastIp) {
                                UserDefaults.standard.set(bloadcastIp, forKey: Const.IP_KEY)
                            }
                            .onAppear {
                                guard let ip = UserDefaults.standard.string(forKey: Const.IP_KEY) else { return }
                                bloadcastIp = ip
                            }
                            Text(bloadcastIp.components(separatedBy: ".").count == 4 ? "" : "invalid ip address")
                                .foregroundStyle(Color.red)
                                .font(.caption)
                        }
                        Button(action: {
                            socketManager.startListener(name: "host_listener")
                            socketManager.connect(host: bloadcastIp, port: "8000", param: .udp)
                        }, label: {
                            Text("通信待受開始")
                        })
                        .buttonStyle(.custom)
                    }
                }
            }
            .onAppear {
                scoreModel.startTimer()
                scoreModel.initialize(entryNames: entryMembers)
            }
            .onDisappear {
                scoreModel.stopTimer()
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
            if data[1] == "DECISION" {
                print("saved \(data)")
                scoreModel.scores[data[2]]![data[3]] = Float(data[4])!
                print(scoreModel.scores)
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

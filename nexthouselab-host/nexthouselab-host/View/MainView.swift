//
//  MainView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI
import Network

struct MainView: View {
    // ネットワーク
    @State var port:NWEndpoint.Port = 9000
    @State var host:NWEndpoint.Host = "127.0.0.1"
    @State var connection: NWConnection?
    // ファイルIO
    @State var selectedFileContent: String = ""
    
    // リストに表示するものたち
    @State var entryMembers = [EntryName(number: 1, name: "kyami"), EntryName(number: 2, name: "amazon"), EntryName(number: 3, name: "Amazon")]
    @State var demoJudgeArrray = [JudgeName(name: "KAZANE"), JudgeName(name: "HIRO"), JudgeName(name: "YUU"), JudgeName(name: "KAZUKIYO")]
    @State var currentNumber: Int = 1
    
    // スクロール同期に関わる部分
    @State var offset: CGFloat = 0
    @State var ges = "ges"
    @State var dragDistance: CGFloat = 0
    @State var preDragPosition: CGFloat = 0
    @State var isFirstDrag = true
    
    var body: some View {
//        Text(ges)
        ZStack {
            VStack {
                // 各ジャッジのリストを表示
                JudgeView(judgeNames: $demoJudgeArrray, entryMembers: $entryMembers, offset: $offset, currentNumber: $currentNumber)
                
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

                // ファイル選択ボタン
                FolderImportView(fileContent: $selectedFileContent)
                    .onChange(of: selectedFileContent, {
                        entryMembers = []
                        let contentArray = selectedFileContent.components(separatedBy: ",")
                        for (i, content) in contentArray.enumerated() {
                            entryMembers.append(EntryName(number: i, name: content))
                        }
                    })
            }
        }
    }
    
    // 接続
    func connect() {
        connection = NWConnection(host: host, port: port, using: .tcp)
        if connection == nil { return }
        connection!.start(queue: .global())
    }
    
    // 送信
    func send(_ payload: Data) {
        if connection == nil { return }
        connection!.send(content: payload, completion: .contentProcessed({sendError in}))
    }
}

#Preview {
    MainView()
}

//
//  SwiftUIView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/06/02.
//

import SwiftUI

struct TopUIGrroupView: View {
    @State var selectedFileContent = ""
    @State var bloadcastIp = ""
    @Binding var entryMembers: [EntryName]
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    @State var isInvalidFile = false

    var body: some View {
        HStack {
            if UIDevice.current.isiPad {
                Spacer()
                VStack(alignment: .leading) {
                    TextField(text: $bloadcastIp, label: {
                        Text("ip")
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
                    if bloadcastIp.components(separatedBy: ".").count == 4 {
                        EmptyView()
                    } else {
                        Text("invalid ip address")
                            .foregroundStyle(Color.red)
                            .font(.caption)
                    }
                }
                Button(action: {
                    socketManager.startListener(name: "host_listener")
                    socketManager.connect(host: bloadcastIp, port: "8000", param: .udp)
                }, label: {
                    Text("通信待受開始")
                })
                .buttonStyle(.custom)
            }
            Spacer()
            if isInvalidFile {
                Text("⚠️適切でない表記のエントリー\nナンバーが含まれています。\n表記の確認を推奨します。")
                    .foregroundStyle(.red)
                    .font(.system(size: 10, weight: .semibold))
            }
            // ファイル選択ボタン
            FolderImportView(fileContent: $selectedFileContent, entryNum: .constant(entryMembers.count))
                .onChange(of: selectedFileContent, {
                    isInvalidFile = false
                    entryMembers = []
                    let contentArray = selectedFileContent.components(separatedBy: "\n")
                    for content in contentArray {
                        let data = content.components(separatedBy: ",")
                        if data.count != 2 { continue }
                        guard let number = Int(data[0])
                        else {
                            isInvalidFile = true
                            continue
                        }
                        entryMembers.append(EntryName(number: number, name: data[1]))
                    }
                    UserDefaults.standard.set(nil, forKey: Const.SCORES_KEY)
                    scoreModel.initialize(entryNames: entryMembers)
                })
                .onAppear{
                    guard let data = UserDefaults.standard.string(forKey: Const.SELCTED_FILE_KEY) else { return }
                    selectedFileContent = data
                }
            FolderExportView()
            Spacer()
        }
    }
}

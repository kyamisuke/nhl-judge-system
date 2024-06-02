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

    var body: some View {
        HStack {
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
            Spacer()
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
            Spacer()
        }
    }
}

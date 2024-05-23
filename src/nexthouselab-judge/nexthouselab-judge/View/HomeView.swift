//
//  HomeView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/06.
//

import SwiftUI
import Foundation

struct HomeView: View {
    @State var name: String = ""
    @State var entryMembers: [EntryName] = []
    @State var selectedFileContent: String = ""
    
    @EnvironmentObject var socketManager: SocketManager
    
    let demo = [
        EntryName(number: 0, name: "kyami"),
        EntryName(number: 1, name: "Kenshu"),
        EntryName(number: 2, name: "Amazon"),
        EntryName(number: 3, name: "Occhi"),
        EntryName(number: 4, name: "Tosai"),
        EntryName(number: 5, name: "Rinki")]
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("What's your name?")
                    .font(.title)
                HStack {
                    TextField(text: $name, label: {
                        Text("Judge Name")
                    })
                    .onChange(of: name) {
                        UserDefaults.standard.set(name, forKey: Const.JUDGE_NAME_KEY)
                    }
                    .onAppear {
                        guard let judgeName = UserDefaults.standard.string(forKey: Const.JUDGE_NAME_KEY) else { return }
                        name = judgeName
                    }
                    NavigationLink("決定") {
                        MainView(judgeName: name, entryNames: entryMembers)
                    }
                }
                .frame(width: 480)
                FolderImportView(fileContent: $selectedFileContent)
                    .onChange(of: selectedFileContent) {
                        var tmpMemberArray: [EntryName] = []
                        let contentAsArray = selectedFileContent.components(separatedBy: "\r\n")
                        for content in contentAsArray {
                            let data = content.components(separatedBy: ",")
                            if data.count != 2 { continue }
                            tmpMemberArray.append(EntryName(number: Int(data[0]) ?? -1, name: data[1]))
                        }
                        entryMembers = tmpMemberArray
                    }
                    .onAppear{
                        guard let data = UserDefaults.standard.string(forKey: Const.SELCTED_FILE_KEY) else { return }
                        selectedFileContent = data
                    }
                //                DemoFolderExportView()
                Button(action: {
                    socketManager.connect(host: "127.0.0.1", port: "9000", param: .udp)
                    socketManager.startListener(name: "judge_listner")
                }, label: {
                    Text("Connect")
                })
            }
        }
    }
}

#Preview {
    HomeView()
}
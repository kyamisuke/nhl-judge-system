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
                    NavigationLink("決定") {
                        MainView(judgeName: name, entryNames: entryMembers)
                    }
                }
                .frame(width: 480)
                FolderImportView(fileContent: $selectedFileContent)
                    .onChange(of: selectedFileContent) {
                        var tmpMemberArray: [EntryName] = []
                        let contentAsArray = selectedFileContent.components(separatedBy: ",")
                        for (i, content) in contentAsArray.enumerated() {
                            tmpMemberArray.append(EntryName(number: i+1, name: content))
                        }
                        entryMembers = tmpMemberArray
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

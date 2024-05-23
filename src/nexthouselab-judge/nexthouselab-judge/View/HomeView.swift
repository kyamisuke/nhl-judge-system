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
    @State var showAlert = false
    @State var navigateToMainView = false
    @State var isChecked = false
    @State var shouldInitialize = true
    
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    
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
                    Button(action: {
                        navigateToMainView = true
                    }, label: {
                        Text("決定")
                    })
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
            .navigationDestination(isPresented: $navigateToMainView) {
                MainView(judgeName: name, entryNames: entryMembers, shouldInitialize: $shouldInitialize)
            }
            .onAppear {
                if isChecked {
                    shouldInitialize = false
                } else {
                    showAlert = UserDefaults.standard.dictionary(forKey: "scores") != nil
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("前回のデータが残っています"),
                    message: Text("前回中断したデータを復元しますか？キャンセルした場合、前回のデータは復元できません。"),
                    primaryButton: .default(Text("復元"), action: {
                        isChecked = true
                        scoreModel.update(scores: UserDefaults.standard.dictionary(forKey: "scores") as! Dictionary<String, Float>)
                        shouldInitialize = false
                        navigateToMainView = true
                    }),
                    secondaryButton: .cancel(Text("キャンセル"), action: {
                        isChecked = true
                        UserDefaults.standard.set(nil, forKey: "scores")
                    })
                )
            }
        }
    }
}

#Preview {
    HomeView()
}

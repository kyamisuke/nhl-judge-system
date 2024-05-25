//
//  HomeView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/06.
//

import SwiftUI
import Foundation

enum AlertType: Identifiable {
    case nameError
    case fileError
    case scoreData
    var id: AlertType { self }
}

struct HomeView: View {
    @State var name: String = ""
    @State var entryMembers: [EntryName] = []
    @State var selectedFileContent: String = ""
    @State var navigateToMainView = false
    @State var alertType: AlertType?
    @State var isChecked = false
    @State var shouldInitialize = true
    @State var hostIp = ""
    
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
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    .onChange(of: name) {
                        UserDefaults.standard.set(name, forKey: Const.JUDGE_NAME_KEY)
                    }
                    .onAppear {
                        guard let judgeName = UserDefaults.standard.string(forKey: Const.JUDGE_NAME_KEY) else { return }
                        name = judgeName
                    }
                    Button(action: {
                        if name.isEmpty {
                            alertType = .nameError
                            return
                        }
                        if selectedFileContent.isEmpty {
                            alertType = .fileError
                            return
                        }
                        navigateToMainView = true
                        isChecked = true
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
                HStack {
                    VStack(alignment: .leading) {
                        TextField(text: $hostIp, label: {
                            Text("host ip")
                        })
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                        .onChange(of: hostIp) {
                            UserDefaults.standard.set(hostIp, forKey: Const.HOST_IP_KEY)
                        }
                        .onAppear {
                            guard let ip = UserDefaults.standard.string(forKey: Const.HOST_IP_KEY) else { return }
                            hostIp = ip
                        }
                        Text(hostIp.components(separatedBy: ".").count == 4 ? "" : "invalid ip address")
                            .foregroundStyle(Color.red)
                            .font(.caption)
                    }
                    Button(action: {
                        if hostIp.isEmpty {
                            return
                        }
                        socketManager.connect(host: hostIp, port: "9000", param: .udp)
                        socketManager.startListener(name: "judge_listner")
                    }, label: {
                        Text("Connect")
                    })
                }
            }
            .navigationDestination(isPresented: $navigateToMainView) {
                MainView(judgeName: name, entryNames: entryMembers, shouldInitialize: $shouldInitialize)
            }
            .onAppear {
                if isChecked {
                    shouldInitialize = false
                } else {
                    if UserDefaults.standard.dictionary(forKey: "scores") != nil {
                        alertType = .scoreData
                    }
                }
            }
            .alert(item: $alertType) { alertType in
                switch alertType {
                case .nameError:
                    return Alert(
                        title: Text("ジャッジの名前が入力されていません。"),
                        message: Text("ジャッジの名前が入力されていることを確認してください。"),
                        dismissButton: .default(Text("戻る"))
                    )
                case .fileError:
                    return Alert(
                        title: Text("エントリーリストが選択されていません。"),
                        message: Text("ファイルを選択し、エントリーリストを設定してください。"),
                        dismissButton: .default(Text("戻る"))
                    )
                case .scoreData:
                    return Alert(
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
}

#Preview {
    HomeView()
}

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
    @State var navigateToMainView = false
    @State var alertType: AlertType?
    @State var isChecked = false
    @State var shouldInitialize = true
    @State var hostIp = ""
    @State var hostArray = [String]()
    @State var currentPlayNum = 1
    @State var mode = Const.Mode.solo

    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    @EnvironmentObject var messageHandler: MessageHandler
    
    let demo = [
        EntryName(number: 0, name: "kyami"),
        EntryName(number: 1, name: "Kenshu"),
        EntryName(number: 2, name: "Amazon"),
        EntryName(number: 3, name: "Occhi"),
        EntryName(number: 4, name: "Tosai"),
        EntryName(number: 5, name: "Rinki")]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("ジャッジの名前を入力してください")
                    .font(.headline)
                HStack {
                    TextField(text: $name, label: {
                        Text("ジャッジ名")
                    })
                    .textFieldStyle(.roundedBorder)
                    .frame(width: AppConfiguration.UI.smallFrameWidth)
                    .onChange(of: name) {
                        UserDefaults.standard.set(name, forKey: AppConfiguration.StorageKeys.judgeName)
                    }
                    .onAppear {
                        guard let judgeName = UserDefaults.standard.string(forKey: AppConfiguration.StorageKeys.judgeName) else { return }
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
                    .buttonStyle(.custom)
                    .tint(.green)
                }
                .frame(width: AppConfiguration.UI.standardFrameWidth)
                HStack {
                    FolderImportView(fileContent: $selectedFileContent)
                        .onChange(of: selectedFileContent) {
                            var tmpMemberArray: [EntryName] = []
                            let contentAsArray = selectedFileContent.components(separatedBy: "\n")
                            for content in contentAsArray {
                                let data = content.components(separatedBy: ",")
                                if data.count != 2 { continue }
                                tmpMemberArray.append(EntryName(number: Int(data[0]) ?? -1, name: data[1]))
                            }
                            entryMembers = tmpMemberArray
                        }
                        .onAppear{
                            guard let data = UserDefaults.standard.string(forKey: AppConfiguration.StorageKeys.selectedFileContents) else { return }
                            selectedFileContent = data
                        }
                    FolderExportView(fileName: name)
                }
                HStack {
                    ForEach(AppConfiguration.ExportGenres.genres, id: \.self) { genre in
                        FolderExportView(fileName: name, sufix: .constant(genre))
                    }
                }
                SelectModeButtonPickerView(selectedMode: $mode)
                    .frame(width: AppConfiguration.UI.mediumFrameWidth)
                Divider()
                SelectHostView(alertType: $alertType, hostArray: $hostArray)
            }
            .navigationDestination(isPresented: $navigateToMainView) {
                MainView(judgeName: name, entryNames: entryMembers, currentPlayNum: $currentPlayNum, shouldInitialize: $shouldInitialize, currentMode: $mode)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ClearablePrincipalIcon(alertType: $alertType)
                }
            }
            .onAppear {
                if isChecked {
                    shouldInitialize = false
                } else {
                    if UserDefaults.standard.dictionary(forKey: "scores") != nil {
                        alertType = .scoreData
                    }
                    socketManager.startListener(name: "judge_listner")
                    hostArrayInit()
                }
            }
            .onChange(of: currentPlayNum) {
                UserDefaults.standard.set(currentPlayNum, forKey: Const.CURRENT_PLAY_NUM_KEY)
            }
            .modifier(HomeAlertModifier(alertType: $alertType, isChecked: $isChecked, shouldInitialize: $shouldInitialize, navigateToMainView: $navigateToMainView, hostIp: $hostIp, currentPlayNum: $currentPlayNum))
        }
    }
    
    func hostArrayInit() {
        guard let hosts = UserDefaults.standard.array(forKey: Const.HOST_KEY) as? [String] else {
            return
        }
        hostArray = hosts
        socketManager.connectAllHosts(hosts: hosts)
    }
}

#Preview {
    struct Sim: View {
        @StateObject var socketManager = SocketManager()
        @StateObject var scoreModel = ScoreModel()
        @StateObject var messageHandler = MessageHandler()
        var body: some View {
            HomeView()
                .environmentObject(socketManager)
                .environmentObject(scoreModel)
                .environmentObject(messageHandler)
                .onAppear {
                    messageHandler.configure(socketManager: socketManager, scoreModel: scoreModel)
                }
        }
    }

    return Sim()
}

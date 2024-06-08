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
            VStack(spacing: 16) {
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
                    .buttonStyle(.custom)
                }
                .frame(width: 480)
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
                            guard let data = UserDefaults.standard.string(forKey: Const.SELCTED_FILE_KEY) else { return }
                            selectedFileContent = data
                        }
                    FolderExportView(fileName: "\(name).csv")
                }
                //                HStack {
                //                    VStack(alignment: .leading) {
                //                        TextField(text: $hostIp, label: {
                //                            Text("host ip")
                //                        })
                //                        .textFieldStyle(.roundedBorder)
                //                        .frame(width: 150)
                //                        .onChange(of: hostIp) {
                //                            UserDefaults.standard.set(hostIp, forKey: Const.HOST_IP_KEY)
                //                        }
                //                        .onAppear {
                //                            guard let ip = UserDefaults.standard.string(forKey: Const.HOST_IP_KEY) else { return }
                //                            hostIp = ip
                //                        }
                //                        if hostIp.components(separatedBy: ".").count == 4 {
                //                            EmptyView()
                //                        } else {
                //                            Text("invalid ip address")
                //                                .foregroundStyle(Color.red)
                //                                .font(.caption)
                //                        }
                //                    }
                //                    Button(action: {
                //                        if hostIp.isEmpty {
                //                            return
                //                        }
                //                        socketManager.connect(host: hostIp, port: "9000", param: .udp)
                //                        socketManager.startListener(name: "judge_listner")
                //                    }, label: {
                //                        Text("Connect")
                //                    })
                //                }
                SelectHostView(hostArray: $hostArray)
            }
            .navigationDestination(isPresented: $navigateToMainView) {
                MainView(judgeName: name, entryNames: entryMembers, shouldInitialize: $shouldInitialize)
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
                }
                socketManager.startListener(name: "judge_listner")
                hostArrayInit()
            }
            .modifier(HomeAlertModifier(alertType: $alertType, isChecked: $isChecked, shouldInitialize: $shouldInitialize, navigateToMainView: $navigateToMainView, hostIp: $hostIp))
        }
    }
    
    func hostArrayInit() {
        guard let hosts = UserDefaults.standard.array(forKey: Const.HOST_KEY) as? [String] else {
            return
        }
        hostArray = hosts
        socketManager.connectAllHosts(hosts: hosts, port: "9000", param: .udp)
    }
}

#Preview {
    struct Sim: View {
        @StateObject var socketManager = SocketManager()
        var body: some View {
            HomeView()
                .environmentObject(socketManager)
        }
    }
    
    return Sim()
}

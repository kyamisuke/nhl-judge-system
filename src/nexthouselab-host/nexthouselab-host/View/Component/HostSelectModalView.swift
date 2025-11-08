//
//  HostSelectModalView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/06/08.
//

import SwiftUI

struct HostSelectModalView: View {
    enum HostAlertType: Identifiable {
        case Empty
        case Invalid
        case IsExited
        
        var id: Int {
            hashValue
        }
        
        var title: String {
            switch self {
            case .Empty:
                return "空欄になっています。"
            case .Invalid:
                return "入力された値は使えません。"
            case .IsExited:
                return "既に登録されています。"
            }
        }
        
        var message: String {
            switch self {
            case .Empty:
                return "アドレスを入力してください。"
            case .Invalid:
                return "X.X.X.Xの形式で入力してください。"
            case .IsExited:
                return "他のアドレスを入力してください。"
            }
        }
    }
    
    @State var host = ""
    @EnvironmentObject var socketManager: SocketManager
    @State var alertType: HostAlertType?
    @Binding var isModal: Bool
    @Binding var hostArray: JudgeIpModel
    @State private var selection = Const.JUDGE_NAMES[0].name
    
    let device = UIDevice.current
    
    var body: some View {
        VStack {
            Button(action: {
                isModal = false
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
            })
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        VStack {
            Spacer()
            HStack {
                Text("この端末のIPアドレス: ")
                if !socketManager.getIPAddresses().isEmpty {
                    Text("\(socketManager.getIPAddresses()[1])")
                        .textSelection(.enabled)
                    Button(action: {
                        UIPasteboard.general.string = socketManager.getIPAddresses()[1]
                    }, label: {
                        Image(systemName: "doc.on.doc.fill")
                    })
                }
            }
            Spacer()
            HStack {
                Text(socketManager.listenerState)
                    .foregroundStyle(socketManager.stateColor)
                Button(action: {
                    socketManagerInit()
                }, label: {
                    Text("接続待受開始")
                })
                .buttonStyle(.custom)
            }
            Spacer()
            HStack {
                Picker("ジャッジの名前を選択", selection: $selection) {
                    ForEach(Const.JUDGE_NAMES) { judge in
                        Text(judge.name).tag(judge.name)
                    }
                }
                TextField("送信先のIPアドレスを入力", text: $host)
                    .frame(width: 200)
                    .textFieldStyle(.roundedBorder)
                Button(action: addRow, label: {
                    Text("登録")
                })
                .buttonStyle(.custom)
            }
            List {
                Section("接続済みホスト一覧") {
                    ForEach(hostArray.keys, id: \.self) { judge in
                        HStack {
                            Text("")
                            Spacer()
                            Text(judge)
                                .frame(width: 150)
                                .fontWeight(.bold)
                            Divider()
                            Text(hostArray.getIp(forKey: judge)!)
                                .frame(width: 150)
                            Spacer()
                            Text("")
                        }
                    }
                    .onDelete(perform: removeRow)
                }
            }
            .padding()
        }
        .alert(item: $alertType) { alertType in
            Alert(
                title: Text(alertType.title),
                message: Text(alertType.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func addRow() {
        if host.isEmpty {
            alertType = .Empty
            return
        }
        if host.components(separatedBy: ".").count != 4 {
            alertType = .Invalid
            return
        }
        for ad in host.components(separatedBy: ".") {
            if Int(ad) == nil {
                alertType = .Invalid
                return
            }
        }
        if hostArray.update(forKey: selection, value: host) == false {
            alertType = .IsExited
            return
        }
        socketManager.connect(host: host)
        host = ""
    }
    
    func removeRow(offsets: IndexSet) {
        // 削除する前に、インデックスセットを配列に変換して並べ替え
        let indices = offsets.sorted()
        // 削除する要素の値を抽出
        let keysToRemove = indices.map { hostArray.keys[$0] }
        keysToRemove.forEach { judge in
            socketManager.disconnect(host: hostArray.getIp(forKey: judge)!)
            let _ = hostArray.remove(forKey: judge)
        }
    }
        
    func socketManagerInit() {
        if device.isiPad {
            DispatchQueue.global(qos: .background).async {
                socketManager.startListener(name: "host-listener")
            }
        } else if device.isiPhone {
            DispatchQueue.global(qos: .background).async {
                socketManager.startListener(name: "host-9000-listener")
                socketManager.startListenerForPhone(name: "host-8000-listener")
            }
        }
    }
}

#Preview {
    struct Sim: View {
        @StateObject var socketManager = SocketManager()
        
        var body: some View {
            HostSelectModalView(isModal: .constant(true), hostArray: .constant(JudgeIpModel()))
                .environmentObject(socketManager)
        }
    }
    
    return Sim()
}

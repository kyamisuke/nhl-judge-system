//
//  SelectHostView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/06/08.
//

import SwiftUI

struct SelectHostView: View {    
    @State var host = ""
    @EnvironmentObject var socketManager: SocketManager
    @Binding var alertType: AlertType?
    @Binding var hostArray: [String]
    
    var body: some View {
//        VStack {
//            Button(action: {
//                isModal = false
//            }, label: {
//                Image(systemName: "xmark.circle.fill")
//                    .resizable()
//                    .frame(width: 32, height: 32)
//            })
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding()
        VStack {
            Spacer()
            
            HStack {
                TextField("送信先のIPアドレスを入力", text: $host)
                    .frame(width: 300)
                    .textFieldStyle(.roundedBorder)
                Button(action: addRow, label: {
                    Text("決定")
                })
                .buttonStyle(.custom)
            }
            List {
                Section("接続済みホスト一覧") {
                    ForEach(hostArray, id: \.self) { ip in
                        HStack {
                            Spacer()
                            Text(ip)
                            Spacer()
                        }
                    }
                    .onDelete(perform: removeRow)
                }
            }
            .padding()
        }
    }
    
    func addRow() {
        if host.isEmpty {
            alertType = .hostIsEmpty
            return
        }
        if host.components(separatedBy: ".").count != 4 {
            alertType = .invalidAddress
            return
        }
        for ad in host.components(separatedBy: ".") {
            if Int(ad) == nil {
                alertType = .invalidAddress
                return
            }
        }
        socketManager.connect(host: host, port: "8000", param: .udp)
        hostArray.append(host)
        save()
        host = ""
    }
    
    func removeRow(offsets: IndexSet) {
        // 削除する前に、インデックスセットを配列に変換して並べ替え
        let indices = offsets.sorted()
        // 削除する要素の値を抽出
        let valuesToRemove = indices.map { hostArray[$0] }
        valuesToRemove.forEach { host in
            socketManager.disconnect(host: host)
        }
        hostArray.remove(atOffsets: offsets)
        save()
    }
    
    func save() {
        UserDefaults.standard.set(hostArray, forKey: Const.HOST_KEY)
    }
}

#Preview {
    struct Sim: View {
        @StateObject var socketManager = SocketManager()
        
        var body: some View {
            SelectHostView(alertType: .constant(nil), hostArray: .constant([String]()))
                .environmentObject(socketManager)
        }
    }
    
    return Sim()
}
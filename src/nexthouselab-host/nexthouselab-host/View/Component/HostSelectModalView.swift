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
        
        var id: Int {
            hashValue
        }
        
        var title: String {
            switch self {
            case .Empty:
                return "空欄になっています。"
            case .Invalid:
                return "入力された値は使えません。"
            }
        }
        
        var message: String {
            switch self {
            case .Empty:
                return "アドレスを入力してください。"
            case .Invalid:
                return "X.X.X.Xの形式で入力してください。"
            }
        }

    }
    
    @State var host = ""
    @EnvironmentObject var socketManager: SocketManager
    @State var alertType: HostAlertType?
    @Binding var isModal: Bool
    
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
        ScrollView {
            VStack {
                Spacer()
                
                HStack {
                    TextField("送信先のIPアドレスを入力", text: $host)
                        .frame(width: 200)
                    Button(action: {
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
                        socketManager.connect(host: host, port: "8000", param: .udp)
                        host = ""
                    }, label: {
                        Text("決定")
                    })
                    .buttonStyle(.custom)
                }
                ForEach(socketManager.connections.map{$0.key}, id: \.self) { ip in
                    Text(ip)
                }
            }
            .alert(item: $alertType) { alertType in
                Alert(
                    title: Text(alertType.title),
                    message: Text(alertType.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    struct Sim: View {
        @StateObject var socketManager = SocketManager()

        var body: some View {
            HostSelectModalView(isModal: .constant(true))
                .environmentObject(socketManager)
        }
    }
    
    return Sim()
}

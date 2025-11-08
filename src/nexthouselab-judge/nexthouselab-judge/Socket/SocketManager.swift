//
//  SocketManager.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/10.
//

import SwiftUI
import Network

final public class SocketManager: ObservableObject {
    // ネットワーク
    @Published var connections = [String: NWConnection]()
    @Published var listenerState = "未接続"
    @Published var stateColor = Color.red
    private var nwListener: NWListener?

    @Published var receivedData: String = ""

    let sendPort: NWEndpoint.Port = NWEndpoint.Port(integerLiteral: AppConfiguration.Network.sendPort)
    let receivePort: NWEndpoint.Port = NWEndpoint.Port(integerLiteral: AppConfiguration.Network.receivePort)
    let param = NWParameters.udp

    // 定数
    let networkType = AppConfiguration.Network.serviceType
    let networkDomain = AppConfiguration.Network.networkDomain
    
    func send(message: String) {
        /* 送信データ生成 */
        guard let data = message.data(using: .utf8) else {
            print("❌ Failed to encode message")
            return
        }

        /* データ送信（非同期） */
        connections.forEach { (host, connection) in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("❌ Send error to \(host): \(error)")
                } else {
                    print("✅ Sent to \(host)")
                }
            })
        }
    }
    
    private func receive(on connection: NWConnection) {
        print("📡 Receive on connection: \(connection)")
        connection.receiveMessage { (data: Data?, contentContext: NWConnection.ContentContext?, aBool: Bool, error: NWError?) in

            if let data = data, let message = String(data: data, encoding: .utf8) {
                print("📨 Received Message: \(message)")
                // メインスレッドで変数更新（asyncに修正してデッドロック防止）
                DispatchQueue.main.async {
                    self.receivedData = message
                }
            }

            if let error = error {
                print("❌ Receive error: \(error)")
            } else {
                // エラーがなければこのメソッドを再帰的に呼ぶ
                self.receive(on: connection)
            }
        }
    }
    
    func startListener(name: String) {
        do {
            // すでに繋がっているなら閉じる
            nwListener?.cancel()
            // キャンセルが完了するのを待つ
            Thread.sleep(forTimeInterval: 0.1)
            // UDPを使用して指定されたポートでリスナーを作成
            let listener = try NWListener(using: param, on: receivePort)
            listener.stateUpdateHandler = { state in
                DispatchQueue.main.async {
                    self.updateListenerState(state: state)
                }
            }

            listener.newConnectionHandler = { [unowned self] newConnection in
                newConnection.start(queue: .global())
                self.receive(on: newConnection)
            }

            listener.start(queue: .main)
            nwListener = listener
            print("🎧 Started listener on port \(self.receivePort)")
        } catch {
            print("❌ Failed to create listener: \(error)")
        }
    }
    
    func updateListenerState(state: NWListener.State)  {
        switch state {
        case .setup:
            print("🔧 Listener setup")
            listenerState = "セットアップ中"
            stateColor = .yellow
        case .waiting(let error):
            print("⏳ Listener waiting: \(error)")
            listenerState =  "待機中"
            stateColor = .yellow
        case .ready:
            print("✅ Listener ready and listening for incoming messages")
            listenerState =  "接続準備完了"
            stateColor = .green
        case .failed(let error):
            print("❌ Listener failed with error: \(error)")
            listenerState =  "失敗しました"
            stateColor = .red
        case .cancelled:
            print("🚫 Listener cancelled")
            listenerState =  "キャンセルしました"
            stateColor = .black
        @unknown default:
            print("❓ Unknown state")
            listenerState =  "未定義"
            stateColor = .yellow
        }
    }
    
    func disconnect(host: String) {
        /* コネクション切断 */
        connections[host]?.cancel()
        connections.removeValue(forKey: host)
        print("🔌 Disconnected from \(host)")
    }

    func connect(host: String, completion: (() -> Void)? = nil) {
        if connections.keys.contains(host) {
            print("ℹ️ Already connected to \(host)")
            completion?()
            return
        }

        let connection: NWConnection
        let t_host = NWEndpoint.Host(host)

        /* コネクションの初期化 */
        connection = NWConnection(host: t_host, port: sendPort, using: param)

        /* コネクションのStateハンドラ設定 */
        connection.stateUpdateHandler = { [weak self] newState in
            switch newState {
            case .ready:
                print("✅ Ready to send to \(host)")
                completion?()
            case .waiting(let error):
                print("⏳ Waiting for \(host): \(error)")
            case .failed(let error):
                print("❌ Failed to connect to \(host): \(error)")
            case .setup:
                print("🔧 Setting up connection to \(host)")
            case .cancelled:
                print("🚫 Connection to \(host) cancelled")
            case .preparing:
                print("⏳ Preparing connection to \(host)")
            @unknown default:
                print("❓ Unknown connection state for \(host)")
            }
        }

        /* コネクション開始 */
        let queue = DispatchQueue(label: "com.nhl.judge.udp.connection.\(host)")
        connection.start(queue: queue)

        connections[host] = connection
    }

    func getIPAddresses() -> [String] {
        var addresses = [String]()
        
        // Retrieve the current interfaces - returns 0 on success
        var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        guard let firstAddr = ifaddr else { return [] }
        
        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            
            // Check for IPv4 or IPv6 interface
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // Convert interface name to a String
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // Change "en0" to the interface you're interested in
                    
                    // Convert the interface address to a human readable string
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count),
                                   nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                        let address = String(cString: hostname)
                        addresses.append(address)
                    }
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return addresses
    }
    
    func connectAllHosts(hosts: [String]) {
        print("🔗 Connecting to \(hosts.count) hosts...")
        hosts.forEach { host in
            connect(host: host)
        }
    }
    
}

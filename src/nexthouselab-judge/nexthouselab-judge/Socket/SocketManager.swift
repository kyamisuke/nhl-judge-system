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
    @Published var listnerStae = "未接続"
    @Published var stateColor = Color.red
    private var nwListener: NWListener?

    @Published var recievedData: String = ""

    let sendPort: NWEndpoint.Port = 9000
    let receivePort: NWEndpoint.Port = 8000
    let param = NWParameters.udp
    
    // 定数
    let networkType = "_networkplayground._udp."
    let networkDomain = "local"
    
    func send(message: String) {
        //        if connection == nil { return }
        //
        //        /* 送信データ生成 */
        //        let data = message.data(using: .utf8)!
        //        let semaphore = DispatchSemaphore(value: 0)
        //
        //        /* データ送信 */
        //        connection.send(content: data, completion: .contentProcessed { error in
        //            if let error = error {
        //                NSLog("\(#function), \(error)")
        //                semaphore.signal()
        //            } else {
        //                semaphore.signal()
        //            }
        //        })
        //        /* 送信完了待ち */
        //        semaphore.wait()
        
        /* 送信データ生成 */
        let data = message.data(using: .utf8)!
        let group = DispatchGroup()
        
        /* データ送信 */
        connections.forEach { (host, connection) in
            group.enter()
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("\(#function), \(error)")
                } else {
                    print("Send to \(host)")
                }
                group.leave()
            })
        }
        /* 送信完了待ち */
        group.wait()
    }
    
    private func receive(on connection: NWConnection) {
        print("receive on connection: \(connection)")
        connection.receiveMessage { (data: Data?, contentContext: NWConnection.ContentContext?, aBool: Bool, error: NWError?) in
            
            if let data = data, let message = String(data: data, encoding: .utf8) {
                print("Received Message: \(message)")
                // メインスレッドで変数更新
                DispatchQueue.main.sync {
                    self.recievedData = message
                }
            }
            
            if let error = error {
                print(error)
            } else {
                // エラーがなければこのメソッドを再帰的に呼ぶ
                self.receive(on: connection)
            }
        }
    }
    
    func startListener(name: String) {
        //        guard let listener = try? NWListener(using: .udp, on: 8000) else { fatalError() }
        //
        //        listener.service = NWListener.Service(name: name, type: networkType)
        //
        //        let listnerQueue = DispatchQueue(label: "com.nhl.judge.system.host.listener")
        //
        //        // 新しいコネクション受診時の処理
        //        listener.newConnectionHandler = { [unowned self] (connection: NWConnection) in
        //            connection.start(queue: listnerQueue)
        //            self.receive(on: connection)
        //        }
        //
        //        // Listener開始
        //        listener.start(queue: listnerQueue)
        //        print("Start Listening as \(listener.service!.name)")
        do {
            // すでに繋がっているなら閉じる
            nwListener?.cancel()
            // キャンセルが完了するのを待つ
            Thread.sleep(forTimeInterval: 0.1)
            // UDPを使用して指定されたポートでリスナーを作成
            let listener = try NWListener(using: param, on: receivePort)
            listener.stateUpdateHandler = { state in
                DispatchQueue.main.async {
                    self.updateListenerStae(state: state)
                }
            }
            
            listener.newConnectionHandler = { [unowned self] newConnection in
                newConnection.start(queue: .global())
                self.receive(on: newConnection)
            }
            
            listener.start(queue: .main)
            nwListener = listener
        } catch {
            print("Failed to create listener: \(error)")
        }
    }
    
    func updateListenerStae(state: NWListener.State)  {
        switch state {
        case .setup:
            print("Listener setup")
            listnerStae = "セットアップ中"
            stateColor = .yellow
        case .waiting(let error):
            print("Listener waiting: \(error)")
            listnerStae =  "待機中"
            stateColor = .yellow
        case .ready:
            print("Listener ready and listening for incoming messages")
            listnerStae =  "接続準備完了"
            stateColor = .green
        case .failed(let error):
            print("Listener failed with error: \(error)")
            listnerStae =  "失敗しました"
            stateColor = .red
        case .cancelled:
            print("Listener cancelled")
            listnerStae =  "キャンセルしました"
            stateColor = .black
        @unknown default:
            print("Unknown state")
            listnerStae =  "未定義"
            stateColor = .yellow
        }
    }
    
    func disconnect(host: String)
    {
        /* コネクション切断 */
        connections[host]?.cancel()
        connections.removeValue(forKey: host)
    }

    func connect(host: String)
    {
        if connections.keys.contains(host) { return }
        
        let connection: NWConnection!
        let t_host = NWEndpoint.Host(host)
        let semaphore = DispatchSemaphore(value: 0)

        /* コネクションの初期化 */
        connection = NWConnection(host: t_host, port: sendPort, using: param)

        /* コネクションのStateハンドラ設定 */
        connection?.stateUpdateHandler = { (newState) in
            switch newState {
                case .ready:
                    NSLog("Ready to send")
                    semaphore.signal()
                case .waiting(let error):
                    NSLog("\(#function), \(error)")
                case .failed(let error):
                    NSLog("\(#function), \(error)")
                case .setup:
                    print("set up")
                case .cancelled:
                    print("cancelled")
                case .preparing:
                    print("preparing")
                @unknown default:
                    fatalError("Illegal state")
            }
        }
        
        /* コネクション開始 */
        let queue = DispatchQueue(label: "_udp._hostConnection")
        connection?.start(queue:queue)

        /* コネクション完了待ち */
        semaphore.wait()
        
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
        let group = DispatchGroup()
        
        hosts.forEach { host in
            if connections.keys.contains(host) { return }
            
            group.enter()
            
            let connection: NWConnection!
            let t_host = NWEndpoint.Host(host)
            
            /* コネクションの初期化 */
            connection = NWConnection(host: t_host, port: sendPort, using: param)
            
            /* コネクションのStateハンドラ設定 */
            connection?.stateUpdateHandler = { (newState) in
                switch newState {
                case .ready:
                    print("Ready to send")
                    group.leave()
                case .waiting(let error):
                    print("\(#function), \(error)")
                case .failed(let error):
                    print("\(#function), \(error)")
                case .setup:
                    print("set up")
                case .cancelled:
                    print("cancelled")
                case .preparing:
                    print("preparing")
                @unknown default:
                    fatalError("Illegal state")
                }
            }
            
            /* コネクション開始 */
            let queue = DispatchQueue(label: "_udp._hostConnection")
            connection?.start(queue:queue)
            
            /* コネクション完了待ち */
            group.wait()
            
            connections[host] = connection
        }
    }
    
}

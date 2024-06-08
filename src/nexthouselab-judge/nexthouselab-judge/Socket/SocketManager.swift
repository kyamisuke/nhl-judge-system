//
//  SocketManager.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/10.
//

import Foundation
import Network

final public class SocketManager: ObservableObject {
    var connection: NWConnection?
    
    @Published var recievedData: String = ""
    
    // 定数
    let networkType = "_networkplayground._udp."
    let networkDomain = "local"
        
    func send(message: String) {
        if connection == nil { return }

        /* 送信データ生成 */
        let data = message.data(using: .utf8)!
        let semaphore = DispatchSemaphore(value: 0)
        
        /* データ送信 */
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                NSLog("\(#function), \(error)")
                semaphore.signal()
            } else {
                semaphore.signal()
            }
        })
        /* 送信完了待ち */
        semaphore.wait()
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
            // UDPを使用して指定されたポートでリスナーを作成
            let listener = try NWListener(using: .udp, on: 8000)
            listener.stateUpdateHandler = { state in
                switch state {
                case .setup:
                    print("Listener setup")
                case .waiting(let error):
                    print("Listener waiting: \(error)")
                case .ready:
                    print("Listener ready and listening for incoming messages")
                case .failed(let error):
                    print("Listener failed with error: \(error)")
                case .cancelled:
                    print("Listener cancelled")
                @unknown default:
                    print("Unknown state")
                }
            }
            
            listener.newConnectionHandler = { [unowned self] newConnection in
                newConnection.start(queue: .global())
                self.receive(on: newConnection)
            }
            
            listener.start(queue: .main)
        } catch {
            print("Failed to create listener: \(error)")
        }
    }
    
    func disconnect(connection: NWConnection)
    {
        /* コネクション切断 */
        connection.cancel()
    }
    
    func connect(host: String, port: String, param: NWParameters)
    {
        connection?.cancel()

        let t_host = NWEndpoint.Host(host)
        let t_port = NWEndpoint.Port(port)
        let semaphore = DispatchSemaphore(value: 0)

        /* コネクションの初期化 */
        connection = NWConnection(host: t_host, port: t_port!, using: param)

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
            case .setup: break
            case .cancelled: break
            case .preparing: break
            @unknown default:
                fatalError("Illegal state")
            }
        }
        
        /* コネクション開始 */
        let queue = DispatchQueue(label: "com.nexthouselab.judge.system.host.connect")
        connection?.start(queue:queue)

        /* コネクション完了待ち */
        semaphore.wait()
//        print(getIPAddresses())
        send(message: "CONNECT/\(getIPAddresses()[1])")
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
}

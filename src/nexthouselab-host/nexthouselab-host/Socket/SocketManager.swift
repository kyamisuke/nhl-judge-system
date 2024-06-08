//
//  SocketManager.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/10.
//

import Foundation
import Network

final public class SocketManager: ObservableObject {
    // ネットワーク
    @Published var connections = [String: NWConnection]()
        
    // 送られてきたデータを監視するところ
    @Published var recievedData: String = ""
    
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
    
    func startListener(name: String) {
//        guard let listener = try? NWListener(using: .udp, on: 9000) else { fatalError() }
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
//        listener.stateUpdateHandler = { state in
//            switch state {
//            case .failed(let error):
//                print("Failed to listen: \(error)")
//            case .ready:
//                print("Start Listening as \(listener.service!.name)")
//            default:
//                break
//            }
//        }
//        DispatchQueue.main.async {
//            self.listenerState = listener.state
//        }
        do {
            // UDPを使用して指定されたポートでリスナーを作成
            let listener = try NWListener(using: .udp, on: 9000)
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
            
            listener.newConnectionHandler = { [weak self] newConnection in
                newConnection.start(queue: .global())
                self?.receive(on: newConnection)
            }
            
            listener.start(queue: .main)
        } catch {
            print("Failed to create listener: \(error)")
        }
    }
    
    func startListenerForPhone(name: String) {
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
//        listener.stateUpdateHandler = { state in
//            switch state {
//            case .failed(let error):
//                print("Failed to listen: \(error)")
//            case .ready:
//                print("Start Listening as \(listener.service!.name)")
//            default:
//                break
//            }
//        }
//        DispatchQueue.main.async {
//            self.listenerStateForPhone = listener.state
//        }
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
    
    func disconnect(host: String)
    {
        /* コネクション切断 */
        connections[host]?.cancel()
        connections.removeValue(forKey: host)
    }
    
    func connect(host: String, port: String, param: NWParameters)
    {
        if connections.keys.contains(host) { return }
        
        let connection: NWConnection!
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
}

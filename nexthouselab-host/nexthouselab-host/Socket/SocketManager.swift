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
    var connection: NWConnection!
        
    // 送られてきたデータを監視するところ
    @Published var recievedData: String = ""
    
    // 定数
    let networkType = "_networkplayground._udp."
    let networkDomain = "local"
            
    func send(message: String) {
        /* 送信データ生成 */
        let data = message.data(using: .utf8)!
        let semaphore = DispatchSemaphore(value: 0)

        /* データ送信 */
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                NSLog("\(#function), \(error)")
            } else {
                semaphore.signal()
            }
        })
        /* 送信完了待ち */
        semaphore.wait()
    }
    
    func startListener(name: String) {
        guard let listener = try? NWListener(using: .udp, on: 9000) else { fatalError() }

        listener.service = NWListener.Service(name: name, type: networkType)

        let listnerQueue = DispatchQueue(label: "com.nhl.judge.system.host.listener")

        // 新しいコネクション受診時の処理
        listener.newConnectionHandler = { [unowned self] (connection: NWConnection) in
            connection.start(queue: listnerQueue)
            self.receive(on: connection)
        }

        // Listener開始
        listener.start(queue: listnerQueue)
        print("Start Listening as \(listener.service!.name)")
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
    
    func disconnect(connection: NWConnection)
    {
        /* コネクション切断 */
        connection.cancel()
    }
    
    func connect(host: String, port: String, param: NWParameters) -> NWConnection
    {
        let t_host = NWEndpoint.Host(host)
        let t_port = NWEndpoint.Port(port)
        let connection: NWConnection
        let semaphore = DispatchSemaphore(value: 0)

        /* コネクションの初期化 */
        connection = NWConnection(host: t_host, port: t_port!, using: param)

        /* コネクションのStateハンドラ設定 */
        connection.stateUpdateHandler = { (newState) in
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
        connection.start(queue:queue)

        /* コネクション完了待ち */
        semaphore.wait()
        return connection
    }
}

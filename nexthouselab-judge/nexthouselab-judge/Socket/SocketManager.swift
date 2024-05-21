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
        
    func send(message: String) {
        if connection == nil { return }

        /* 送信データ生成 */
        let data = message.data(using: .utf8)!
        let semaphore = DispatchSemaphore(value: 0)
        
        /* データ送信 */
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                NSLog("\(#function), \(error)")
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
    
    func disconnect(connection: NWConnection)
    {
        /* コネクション切断 */
        connection.cancel()
    }
    
    func connect(host: String, port: String, param: NWParameters)
    {
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
        let queue = DispatchQueue(label: "example")
        connection?.start(queue:queue)

        /* コネクション完了待ち */
        semaphore.wait()
    }
}

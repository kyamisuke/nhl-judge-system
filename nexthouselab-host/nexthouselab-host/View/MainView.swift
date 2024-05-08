//
//  MainView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI
import Network

struct MainView: View {
    @State var port:NWEndpoint.Port = 9000
    @State var host:NWEndpoint.Host = "127.0.0.1"
    @State var connection: NWConnection?
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    
    func connect() {
        connection = NWConnection(host: host, port: port, using: .tcp)
        if connection == nil { return }
        connection!.start(queue: .global())
    }
    
    func send(_ payload: Data) {
        if connection == nil { return }
        connection!.send(content: payload, completion: .contentProcessed({sendError in}))
    }
}

#Preview {
    MainView()
}

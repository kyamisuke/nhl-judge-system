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
    @State var selectedFileContent: String = ""
    @State var entryMembers = [EntryName(number: 0, name: "kyami"), EntryName(number: 1, name: "amazon"), EntryName(number: 2, name: "Amazon")]
    @State var demoJudgeArrray = [JudgeName(name: "KAZANE"), JudgeName(name: "HIRO"), JudgeName(name: "YUU"), JudgeName(name: "KAZUKIYO")]
    @State var offset: Int? = 0
    @State var ges = "ges"
    @State var dragDistance: CGFloat = 0
    @State var preDragPosition: CGFloat = 0
    @State var isFirstDrag = true
    
    var body: some View {
//        Text(ges)
        ZStack {
            VStack {
                HStack {
                    ForEach($demoJudgeArrray) { judge in
                        JudgeView(judgeName: judge, entryMembers: $entryMembers, offset: $offset)
                    }
                }
                FolderImportView(fileContent: $selectedFileContent)
                    .onChange(of: selectedFileContent, {
                        entryMembers = []
                        let contentArray = selectedFileContent.components(separatedBy: ",")
                        for (i, content) in contentArray.enumerated() {
                            entryMembers.append(EntryName(number: i, name: content))
                        }
                    })
            }
            Color(red: 1, green: 1, blue: 1, opacity: 0.1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    DragGesture()
                        .onChanged {gesture in
                            if isFirstDrag {
                                isFirstDrag = false
                                preDragPosition = gesture.startLocation.y
                                return
                            }
                            dragDistance += (preDragPosition - gesture.location.y) / 50
                            
                            preDragPosition = gesture.location.y
                            offset = Int(dragDistance)
                            self.ges = "\(gesture.startLocation), \(gesture.location), \(dragDistance)"
                        }
                        .onEnded {_ in
                            isFirstDrag = true
                            if dragDistance < 0 {
                                dragDistance = 0
                                offset = Int(dragDistance)
                            }
                        }
                )
        }
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

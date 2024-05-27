//
//  MainView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/06.
//

import SwiftUI
import Combine

struct MainView: View {
    let judgeName: String
    let entryNames: [EntryName]
    @State var currentEditingNum = 0
    @State var currentPlayNum = 1
    @Binding var shouldInitialize: Bool
    
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
        
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("\(judgeName), Please fill all score.")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                Spacer()
                Text("auto saved: \(scoreModel.udpatedTime)")
                Spacer()
            }
            Spacer()
            List(entryNames) {entryName in
                EntryListItemView(entryName: entryName, currentPlayNum: $currentPlayNum, currentEdintingNum: $currentEditingNum)
            }
            .onChange(of: currentEditingNum) {
                socketManager.send(message: "EDITING/\(judgeName)/\(currentEditingNum)")
            }
            .onChange(of: socketManager.recievedData) {
                DispatchQueue.main.async {
                    guard let currentPlayNum = Int(socketManager.recievedData) else { return }
                    self.currentPlayNum = currentPlayNum
                }
            }

            Spacer()
            FolderExportView(fileName: "\(judgeName).csv")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if shouldInitialize {
                scoreModel.initialize(entryList: entryNames)
            }
            scoreModel.startTimer()
        }
        .onDisappear {
            scoreModel.stopTimer()
        }
//        .background(.orange)
    }
}

#Preview {
    struct Sim: View {
        @State var socketManager = SocketManager()
        @State var scoreModel = ScoreModel()
        
        var body: some View {
            MainView(judgeName: "KAZANE", entryNames: [
                EntryName(number: 1, name: "Kenshu"),
                EntryName(number: 2, name: "Amazon"),
                EntryName(number: 3, name: "Occhi"),
                EntryName(number: 4, name: "Tosai"),
                EntryName(number: 5, name: "Rinki"),
                EntryName(number: 0, name: "kyami")
            ], shouldInitialize: .constant(true))
            .environmentObject(socketManager)
            .environmentObject(scoreModel)
        }
    }
    
    return Sim()
}

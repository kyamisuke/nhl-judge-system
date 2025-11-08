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
    @Binding var currentPlayNum: Int
    @State var tappedId = 1
    @Binding var shouldInitialize: Bool
    @Binding var currentMode: Const.Mode

    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    @EnvironmentObject var messageHandler: MessageHandler
        
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                HStack {
                    Text("\(judgeName), Please enter all score.")
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                    Spacer()
                    Text("auto saved: \(scoreModel.updatedTime)")
                    Spacer()
                }
                Spacer()
                List(entryNames) {entryName in
                    EntryListItemView(entryName: entryName, currentPlayNum: $currentPlayNum, currentEdintingNum: $currentEditingNum, judgeName: judgeName, tappedId: $tappedId, currentMode: $currentMode)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tappedId = entryName.number
                        }
                }
                .onChange(of: currentEditingNum) {
                    let message = NetworkMessage.editing(judgeName: judgeName, entryNumber: currentEditingNum)
                    messageHandler.sendMessage(message)
                }
                .onChange(of: socketManager.receivedData) {
                    messageHandler.handleMessage(socketManager.receivedData)
                }
                .onChange(of: messageHandler.currentNumber) {
                    self.currentPlayNum = messageHandler.currentNumber
                }
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PrincipalIcon()
                }
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
            .navigationBarBackButtonHidden(true)
        }
//        .background(.orange)
    }
}

#Preview {
    struct Sim: View {
        @StateObject var socketManager = SocketManager()
        @StateObject var scoreModel = ScoreModel()
        @StateObject var messageHandler = MessageHandler()
        @State var mode = Const.Mode.solo

        var body: some View {
            MainView(judgeName: "KAZANE", entryNames: [
                EntryName(number: 1, name: "Kenshu"),
                EntryName(number: 2, name: "Amazon"),
                EntryName(number: 3, name: "Occhi"),
                EntryName(number: 4, name: "Tosai"),
                EntryName(number: 5, name: "Rinki"),
                EntryName(number: 6, name: "kyami")
            ], currentPlayNum: .constant(1), shouldInitialize: .constant(true), currentMode: $mode)
            .environmentObject(socketManager)
            .environmentObject(scoreModel)
            .environmentObject(messageHandler)
            .onAppear {
                messageHandler.configure(socketManager: socketManager, scoreModel: scoreModel)
            }
        }
    }

    return Sim()
}

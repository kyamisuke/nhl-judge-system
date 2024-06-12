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
    
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
        
    var body: some View {
        NavigationStack {
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
                    EntryListItemView(entryName: entryName, currentPlayNum: $currentPlayNum, currentEdintingNum: $currentEditingNum, judgeName: judgeName, tappedId: $tappedId)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tappedId = entryName.number
                        }
                }
                .onChange(of: currentEditingNum) {
                    socketManager.send(message: "EDITING/\(judgeName)/\(currentEditingNum)")
                }
                .onChange(of: socketManager.recievedData) {
                    if let currentPlayNum = Int(socketManager.recievedData) {
                        self.currentPlayNum = currentPlayNum
                    } else if socketManager.recievedData == "UPDATE" {
                        do {
                            // DictionaryをJSONデータに変換
                            let jsonData = try JSONSerialization.data(withJSONObject: scoreModel.scores)
                            // JSONデータを文字列に変換
                            let jsonStr = String(bytes: jsonData, encoding: .utf8)!
                            print(jsonStr)
                            socketManager.send(message: "UPDATE/\(jsonStr)")
                        } catch (let e) {
                            print(e)
                        }
                    }
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
        @State var socketManager = SocketManager()
        @State var scoreModel = ScoreModel()
        
        var body: some View {
            MainView(judgeName: "KAZANE", entryNames: [
                EntryName(number: 1, name: "Kenshu"),
                EntryName(number: 2, name: "Amazon"),
                EntryName(number: 3, name: "Occhi"),
                EntryName(number: 4, name: "Tosai"),
                EntryName(number: 5, name: "Rinki"),
                EntryName(number: 6, name: "kyami")
            ], currentPlayNum: .constant(1), shouldInitialize: .constant(true))
            .environmentObject(socketManager)
            .environmentObject(scoreModel)
        }
    }
    
    return Sim()
}

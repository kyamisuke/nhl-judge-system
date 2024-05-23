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
    
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    
    private var timer: Timer?
    private var cancellable: AnyCancellable?
    
    init(judgeName: String, entryNames: [EntryName]) {
        self.judgeName = judgeName
        self.entryNames = entryNames
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("\(judgeName), Please fill all score.")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            Spacer()
            List(entryNames) {entryName in
                EntryListItemView(entryName: entryName, currentEdintingNum: $currentEditingNum)
            }
            .onChange(of: currentEditingNum) {
                socketManager.send(message: "EDITING/\(judgeName)/\(currentEditingNum)")
            }
            Spacer()
            FolderExportView(fileName: "\(judgeName).csv")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            scoreModel.initialize(entryList: entryNames)
        }
//        .background(.orange)
    }
    
//    private func startTimer() {
//        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
//            print("saved")
//        }
//    }
//    
//    private func saveCounter() {
//        UserDefaults.standard.set(counter, forKey: "counter")
//    }
}

#Preview {
    struct Sim: View {
        @State var socketManager = SocketManager()
        
        var body: some View {
            MainView(judgeName: "KAZANE", entryNames: [
                EntryName(number: 1, name: "Kenshu"),
                EntryName(number: 2, name: "Amazon"),
                EntryName(number: 3, name: "Occhi"),
                EntryName(number: 4, name: "Tosai"),
                EntryName(number: 5, name: "Rinki"),
                EntryName(number: 0, name: "kyami")
                ])
            .environmentObject(socketManager)
        }
    }
    
    return Sim()
}

//
//  MainView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/06.
//

import SwiftUI

struct MainView: View {
    let judgeName: String
    let entryNames: [EntryName]
    @State var demoScores: [Float] = [0, 0, 0, 0, 0, 0]
    @State var currentEditingNum = 0
    
    @EnvironmentObject var socketManager: SocketManager
    
    var body: some View {
        VStack {
            Spacer()
            Text("\(judgeName), Please fill all score.")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            Spacer()
            List(entryNames) {entryName in
                EntryListItemView(entryName: entryName, scores: $demoScores, currentEdintingNum: $currentEditingNum)
            }
            .onChange(of: currentEditingNum) {
                socketManager.send(message: "\(judgeName)/\(currentEditingNum)")
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(.orange)
    }
}

#Preview {
    MainView(judgeName: "KAZANE", entryNames: [
        EntryName(number: 0, name: "kyami"),
        EntryName(number: 1, name: "Kenshu"),
        EntryName(number: 2, name: "Amazon"),
        EntryName(number: 3, name: "Occhi"),
        EntryName(number: 4, name: "Tosai"),
        EntryName(number: 5, name: "Rinki")])
}

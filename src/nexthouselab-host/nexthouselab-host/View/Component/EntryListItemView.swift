//
//  EntryListItemView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI

struct EntryListItemView: View {
    var entryName: EntryName
    @State var isFilling = false
    @Binding var currentNumber: Int
    let judgeName: String
    @Binding var currentMessage: Message
    @State var isEditing: Bool = false
    @Binding var mode: Const.Mode
    
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    
    var body: some View {
        HStack {
            Text(String(entryName.number))
                .frame(width: 32)
            Text(entryName.name)
                .frame(width: 80)
            Text(getLabel())
                .frame(width: 32, height: 32)
                .foregroundStyle(getLabel() == "未" ? Color.red : Color.black)
                .background(
                    Circle()
                        .foregroundStyle(.white)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(getBackgroundColor())
        .border(isEditing ? Color.green : Color.clear, width: 4)
        .onChange(of: currentMessage, checkEditing)
    }
    
    private func isFocus() -> Bool {
        switch mode {
        case .solo:
            return entryName.number == currentNumber
        case .dual:
            return entryName.number == currentNumber || entryName.number == currentNumber + 1
        }
    }

    private func getBackgroundColor() -> Color {
        if isFocus() {
            switch mode {
            case .solo:
                return Color("oddColor")
            case .dual:
                if entryName.number % 2 == 1 {
                    return Color("oddColor")
                } else {
                    return Color("evenColor")
                }
            }
        } else {
            return .clear
        }
    }
    
    private func checkEditing() {
        if judgeName == currentMessage.judgeName {
            isEditing = entryName.number == currentMessage.number
        }
    }

    private func getLabel() -> String {
        let score = scoreModel.getScore(in: judgeName, for: String(entryName.number)).wrappedValue
        if let score = score {
            return String(score)
        } else {
            return "未"
        }
    }
}

private struct ScoreSliderView: View {
    let num: Int
    
    var body: some View {
        if (num+1) % 2 == 1 {
            Text(String(num / 2))
        }
        else {
            Text(".")
        }
        if num != 20 {
            Spacer()
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var demoScores: [Float] = [0, 0, 0, 0, 0, 0]
        @StateObject var socketManager = SocketManager()
        @StateObject var scoreModel = ScoreModel()

        var body: some View {
            EntryListItemView(entryName: EntryName(number: 1, name: "kyami"), currentNumber: .constant(1), judgeName: "KAZANE", currentMessage: .constant(Message(judgeName: "KAZANE", number: 1)), mode: .constant(.solo))
                .environmentObject(socketManager)
                .environmentObject(scoreModel)
        }
    }
    
    return PreviewView()
}

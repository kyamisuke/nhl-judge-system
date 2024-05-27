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
    @State var stateLabel = "未"
    
    @EnvironmentObject var socketManager: SocketManager
    
    var body: some View {
        HStack(spacing: 24) {
            Text(String(entryName.number))
                .frame(width: 32)
            Text(entryName.name)
                .frame(width: 80)
            Text(stateLabel)
                .frame(width: 32, height: 32)
                .foregroundStyle(stateLabel == "未" ? Color.red : Color.black)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(isFocus() ? Color.green : Color.white)
        .border(isEditing ? Color.red : Color.clear, width: 4)
        .onChange(of: currentMessage, checkEditing)
        .onChange(of: socketManager.recievedData, receiveData)

    }
    
    private func onClickButton() {
        isFilling = true
    }
    
    private func isFocus() -> Bool {
        
        return entryName.number == currentNumber || entryName.number == currentNumber + 1
    }
    
    private func checkEditing() {
        if judgeName == currentMessage.judgeName {
            isEditing = entryName.number == currentMessage.number
        }
    }
    
    private func receiveData() {
        let data = socketManager.recievedData.components(separatedBy: "/")
        if data[0] == "SCORER" {
            if data[1] == "DECISION" {
                if judgeName == data[2] && entryName.number == Int(data[3])! {
                    stateLabel = data[4]
                }
            } else if data[1] == "CANCEL" {
                if judgeName == data[2] && entryName.number == Int(data[3])! {
                    stateLabel = "未"
                }
            }
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
        @State var socketManager = SocketManager()

        var body: some View {
            EntryListItemView(entryName: EntryName(number: 1, name: "kyami"), currentNumber: .constant(5), judgeName: "KAZANE", currentMessage: .constant(Message(judgeName: "KAZANE", number: 1)))
                .environmentObject(socketManager)
        }
    }
    
    return PreviewView()
}

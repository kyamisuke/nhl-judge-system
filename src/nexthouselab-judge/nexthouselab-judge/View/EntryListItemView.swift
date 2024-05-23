//
//  EntryListItemView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/06.
//

import SwiftUI

struct EntryName: Identifiable {
    let id = UUID()
    let number: Int
    let name: String
}

struct EntryListItemView: View {
    var entryName: EntryName
    @State var currentPlayNum = 1
    @Binding var currentEdintingNum: Int
    
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    
    var body: some View {
        HStack(spacing: 24) {
            Text(String(entryName.number))
                .frame(width: 32)
            Text(entryName.name)
                .frame(width: 100)
            VStack {
                HStack {
                    ForEach(0..<21) {num in
                        ScoreSliderView(num: num)
                    }
                }
                .padding(8)
                Slider(value: scoreModel.getScore(for: String(entryName.number)), in: 0...10, step: 0.5)
                    .onChange(of: scoreModel.getScore(for: String(entryName.number)).wrappedValue) {
                        currentEdintingNum = entryName.number
                    }
            }
            .frame(width: 480)
            ZStack {
                Text(String(scoreModel.getScore(for: String(entryName.number)).wrappedValue))
                    .frame(width: 48)
                // 上の円
                Circle()
                    .trim(from: 0.0, to: CGFloat(scoreModel.getScore(for: String(entryName.number)).wrappedValue) / 10.0) // 線のトリム
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(
                            lineWidth: 6,
                            lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(isPlaying() ? Color.green : Color.white)
        .onChange(of: socketManager.recievedData) {
            guard let currentPlayNum = Int(socketManager.recievedData) else { return }
            self.currentPlayNum = currentPlayNum
        }
    }
    
    func isPlaying() -> Bool {
        return currentPlayNum == entryName.number || currentPlayNum + 1 == entryName.number
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
            EntryListItemView(entryName: EntryName(number: 1, name: "kyami"), currentEdintingNum: .constant(1))
                .environmentObject(socketManager)
        }
    }
    
    return PreviewView()
}

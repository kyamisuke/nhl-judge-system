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
    let entryName: EntryName
    @Binding var currentPlayNum: Int
    @Binding var currentEdintingNum: Int
    @State var isDone = false
    @State var wasOnStage = false
    let judgeName: String
    
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    
    var body: some View {
        HStack(spacing: 24) {
            Spacer()
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
                if !isDone && wasOnStage {
                    Slider(value: scoreModel.getScore(for: String(entryName.number)), in: 0...10, step: 0.5)
                        .onChange(of: scoreModel.getScore(for: String(entryName.number)).wrappedValue) {
                            currentEdintingNum = entryName.number
                        }
                } else {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .frame(height: 32)
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
            if wasOnStage {
                Button(action: {
                    isDone.toggle()
                    if isDone {
                        socketManager.send(message: "SCORER/DECISION/\(judgeName)/\(entryName.number)/\(scoreModel.getScore(for: String(entryName.number)).wrappedValue)")
                    } else {
                        socketManager.send(message: "SCORER/CANCEL/\(judgeName)/\(entryName.number)")
                    }
                }, label: {
                    Text(isDone ? "編集" : "決定")
                })
                .buttonStyle(BorderlessButtonStyle())
                .frame(width: 32)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(getBackgroundColor())
        .onChange(of: currentPlayNum) {
            wasOnStage = wasOnStage || isPlaying()
        }
        .onAppear {
            wasOnStage = wasOnStage || isPlaying()
        }
    }
    
    func isPlaying() -> Bool {
        return currentPlayNum == entryName.number || currentPlayNum + 1 == entryName.number
    }
        
    func getBackgroundColor() -> Color {
        if isPlaying() {
            return .green
        } else if isDone {
            return .gray
        } else {
            return .white
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
        @State var scoreModel = ScoreModel()
        
        var body: some View {
            List {
                EntryListItemView(entryName: EntryName(number: 1, name: "kyami"), currentPlayNum: .constant(1), currentEdintingNum: .constant(1), judgeName: "HIRO")
                    .environmentObject(socketManager)
                    .environmentObject(scoreModel)
            }
        }
    }
    
    return PreviewView()
}

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
    var isDone: Bool {
        get {
            return scoreModel.getDoneState(for: String(entryName.number)).wrappedValue
        }
    }
    @State var wasOnStage = false
    let judgeName: String
    @Binding var tappedId: Int
    let buttonColor = Color.init(red: 0.38, green: 0.28, blue: 0.86)
    let lightColor = Color.init(red: 0.54, green: 0.41, blue: 0.95)
    let shadowColor = Color.init(red: 0.25, green: 0.17, blue: 0.75)
    let radius = CGFloat(12)
    
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            Text(String(entryName.number))
                .frame(width: 32)
            Text(entryName.name)
                .frame(width: 80)
            VStack {
                HStack {
                    ForEach(0..<21) {num in
                        ScoreSliderView(num: num)
                    }
                }
                .padding(8)
                if isTapped() && !isDone {
                    Slider(value: scoreModel.getScore(for: String(entryName.number)), in: 0...10, step: 0.5)
                        .onChange(of: scoreModel.getScore(for: String(entryName.number)).wrappedValue) {
                            currentEdintingNum = entryName.number
                        }
                        .tint(Const.scoreColor)
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
                        Color.green,
                        style: StrokeStyle(
                            lineWidth: 6,
                            lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
            }
            if isTapped() {
                if isDone {
                    CrayButtonView(label: "編集", action: tapButton, lightColor: Const.rewriteLightColor, shadowColor: Const.rewriteShadowColor, buttonColor: Const.rewriteButtonColor, radius: radius)
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(width: 64)
                } else {
                    CrayButtonView(label: "決定", action: tapButton, lightColor: Const.selectLightColor, shadowColor: Const.selectShadowColor, buttonColor: Const.selectButtonColor, radius: radius)
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(width: 64)
                }
                
            } else {
                if isDone {
                    Text("済")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .frame(width: 32)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: radius)
                                .foregroundStyle(.black)
                        )
                } else {
                    Text("未")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .frame(width: 32)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: radius)
                                .foregroundStyle(.red)
                        )
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(getBackgroundColor())
        .onChange(of: currentPlayNum) {
            wasOnStage = currentPlayNum + 1 >= entryName.number
        }
        .onAppear {
            wasOnStage = currentPlayNum + 1 >= entryName.number
        }
    }
    
    func isPlaying() -> Bool {
        return currentPlayNum == entryName.number || currentPlayNum + 1 == entryName.number
    }
    
    func getBackgroundColor() -> Color {
        if isPlaying() {
            if entryName.number % 2 == 1 {
                return Const.oddColor
            }
            else {
                return Const.evenColor
            }
        } else if isDone {
            return Const.fixedColor
        } else {
            return .white
        }
    }
    
    func isTapped() -> Bool {
        if tappedId % 2 == 1 {
            return entryName.number == tappedId || entryName.number == tappedId + 1
        } else {
            return entryName.number == tappedId - 1 || entryName.number == tappedId
        }
    }
    
    func tapButton() {
        scoreModel.updateDoneState(in: String(entryName.number), value: !isDone)
        if isDone {
            socketManager.send(message: "SCORER/DECISION/\(judgeName)/\(entryName.number)/\(scoreModel.getScore(for: String(entryName.number)).wrappedValue)")
        } else {
            socketManager.send(message: "SCORER/CANCEL/\(judgeName)/\(entryName.number)/-1")
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
                EntryListItemView(entryName: EntryName(number: 1, name: "kyami"), currentPlayNum: .constant(5), currentEdintingNum: .constant(1), judgeName: "HIRO", tappedId: .constant(1))
                    .environmentObject(socketManager)
                    .environmentObject(scoreModel)
            }
        }
    }
    
    return PreviewView()
}

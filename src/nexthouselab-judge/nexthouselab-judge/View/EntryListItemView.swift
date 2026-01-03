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
    @Binding var currentMode: Const.Mode

    let radius = AppConfiguration.UI.buttonRadius
    let buttonFontSize: CGFloat = Locale.current == Locale(identifier: "ja_JP") ?
        AppConfiguration.UI.japaneseButtonFontSize :
        AppConfiguration.UI.englishButtonFontSize

    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var scoreModel: ScoreModel
    @EnvironmentObject var messageHandler: MessageHandler
    
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            Text(String(entryName.number))
                .frame(width: 32)
            Text(entryName.name)
                .frame(width: 80)
            VStack {
                HStack {
                    ForEach(0..<AppConfiguration.Scores.tickCount) {num in
                        ScoreSliderView(num: num)
                    }
                }
                .padding(8)
                if isTapped() && !isDone {
                    Slider(
                        value: scoreModel.getScore(for: String(entryName.number)),
                        in: AppConfiguration.Scores.minValue...AppConfiguration.Scores.maxValue,
                        step: AppConfiguration.Scores.step
                    )
                    .onChange(of: scoreModel.getScore(for: String(entryName.number)).wrappedValue) {
                        currentEdintingNum = entryName.number
                    }
                    .tint(Color(R.color.scoreColor))
                } else {
                    Rectangle()
                        .foregroundStyle(.clear)
                        .frame(height: 32)
                }
            }
            .frame(width: AppConfiguration.UI.standardFrameWidth)
            ZStack {
                Text(String(scoreModel.getScore(for: String(entryName.number)).wrappedValue))
                    .frame(width: 48)
                // 上の円
                Circle()
                    .trim(from: 0.0, to: CGFloat(scoreModel.getScore(for: String(entryName.number)).wrappedValue) / CGFloat(AppConfiguration.Scores.maxValue)) // 線のトリム
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
                    CrayButtonView(label: R.string.localizable.edit(), action: tapButton, lightColor: Color(R.color.rewriteLightColor), shadowColor: Color(R.color.rewriteShadowColor), buttonColor: Color(R.color.rewriteButtonColor), radius: radius, fontSize: buttonFontSize)
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(width: 64)
                } else {
                    CrayButtonView(label: R.string.localizable.ok(), action: tapButton, lightColor: Color(R.color.selectLightColor), shadowColor: Color(R.color.selectShadowColor), buttonColor: Color(R.color.selectButtonColor), radius: radius, fontSize: buttonFontSize)
                        .buttonStyle(BorderlessButtonStyle())
                        .frame(width: 64)
                }
                
            } else {
                if isDone {
                    Text(R.string.localizable.done())
                        .font(.system(size: buttonFontSize, weight: .semibold, design: .default))
                        .frame(width: 32)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: radius)
                                .foregroundStyle(.black)
                        )
                } else {
                    Text(R.string.localizable.notYet())
                        .font(.system(size: buttonFontSize, weight: .semibold, design: .default))
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
        switch currentMode {
        case .solo:
            return currentPlayNum == entryName.number
        case .dual:
            return currentPlayNum == entryName.number || currentPlayNum + 1 == entryName.number
        }
    }
    
    func getBackgroundColor() -> Color {
        if isPlaying() && false {
            switch currentMode {
            case .solo:
                return Color(R.color.oddColor)
            case .dual:
                if entryName.number % 2 == 1 {
                    return Color(R.color.oddColor)
                }
                else {
                    return Color(R.color.evenColor)
                }
            }
        } else if isDone {
            return Color(R.color.fixedColor)
        } else {
            return .white
        }
    }
    
    func isTapped() -> Bool {
        switch currentMode {
        case .solo:
            return entryName.number == tappedId
        case .dual:
            if tappedId % 2 == 1 {
                return entryName.number == tappedId || entryName.number == tappedId + 1
            } else {
                return entryName.number == tappedId - 1 || entryName.number == tappedId
            }
        }
    }
    
    func tapButton() {
        scoreModel.updateDoneState(in: String(entryName.number), value: !isDone)
        if isDone {
            let score = scoreModel.getScore(for: String(entryName.number)).wrappedValue
            let message = NetworkMessage.decision(
                judgeName: judgeName,
                entryNumber: entryName.number,
                score: score
            )
            messageHandler.sendMessage(message)
        } else {
            let message = NetworkMessage.cancel(
                judgeName: judgeName,
                entryNumber: entryName.number
            )
            messageHandler.sendMessage(message)
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
        @StateObject var messageHandler = MessageHandler()
        @State var mode = Const.Mode.solo

        var body: some View {
            List {
                EntryListItemView(entryName: EntryName(number: 1, name: "kyami"), currentPlayNum: .constant(5), currentEdintingNum: .constant(1), judgeName: "HIRO", tappedId: .constant(1), currentMode: $mode)
                    .environmentObject(socketManager)
                    .environmentObject(scoreModel)
                    .environmentObject(messageHandler)
            }
            .onAppear {
                messageHandler.configure(socketManager: socketManager, scoreModel: scoreModel)
            }
        }
    }

    return PreviewView()
}

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
    @Binding var scores: [Float]
    @State var isFilling = false
    
    var body: some View {
        HStack(spacing: 24) {
            Text(String(entryName.number))
                .frame(width: 16)
            Text(entryName.name)
                .frame(width: 100)
            VStack {
                HStack {
                    ForEach(0..<21) {num in
                        ScoreSliderView(num: num)
                    }
                }
                .padding(8)
                Slider(value: $scores[entryName.number], in: 0...10, step: 0.5)
            }
            .frame(width: 480)
            Text(String(scores[entryName.number]))
                .frame(width: 48)
//            Button(action: onClickButton, label: {
//                Text("決定")
//            })
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(isFilling ? Color.gray : Color.white)
    }
    
    private func onClickButton() {
        isFilling = true
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
        
        var body: some View {
            EntryListItemView(entryName: EntryName(number: 0, name: "kyami"), scores: $demoScores)
        }
    }
    
    return PreviewView()
}

//
//  EntryListItemView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI

struct EntryName: Identifiable {
    let id = UUID()
    let number: Int
    let name: String
}

struct EntryListItemView: View {
    var entryName: EntryName
    @State var isFilling = false
    @Binding var currentNumber: Int
    
    var body: some View {
        HStack(spacing: 24) {
            Text(String(entryName.number))
                .frame(width: 32)
            Text(entryName.name)
                .frame(width: 100)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(isFocus() ? Color(hue: 0, saturation: 0.5, brightness: 1.0) : Color.white)
    }
    
    private func onClickButton() {
        isFilling = true
    }
    
    private func isFocus() -> Bool {
        return entryName.number == currentNumber || entryName.number == currentNumber + 1
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
            EntryListItemView(entryName: EntryName(number: 1, name: "kyami"), currentNumber: .constant(1))
        }
    }
    
    return PreviewView()
}

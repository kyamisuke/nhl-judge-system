//
//  SelectModeButtonPickerView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/12/15.
//

import SwiftUI

struct SelectModeButtonPickerView: View {
    @Binding var selectedMode: Const.Mode
    
    init(selectedMode: Binding<Const.Mode>) {
        self._selectedMode = selectedMode
        
        // 背景色
        UISegmentedControl.appearance().backgroundColor = .white
        // 選択項目の背景色
        UISegmentedControl.appearance().selectedSegmentTintColor = R.color.scoreColor()
        // 選択項目の文字色
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }
    
    var body: some View {
        // Mode Picker
        Picker("periods", selection: $selectedMode) {
            ForEach(Const.Mode.allCases) {
                Text($0.rawValue).tag($0)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
}

#Preview {
    struct Sim: View {
        @State var selectedMode: Const.Mode = .Solo
        var body: some View {
            SelectModeButtonPickerView(selectedMode: $selectedMode)
        }
    }
    
    return Sim()
}

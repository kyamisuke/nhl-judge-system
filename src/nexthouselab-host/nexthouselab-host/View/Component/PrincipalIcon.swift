//
//  PrincipalIcon.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/31.
//

import SwiftUI

struct PrincipalIcon: View {
    let entryMembers: [EntryName]
    @EnvironmentObject var scoreModel: ScoreModel
    @Binding var onClearAction: Bool
    
    var body: some View {
        principalIcon()
    }
    
    private func principalIcon() -> some View {
        Image("icon")
            .resizable()
            .scaledToFill()
            .frame(width: 48, height: 48)
            .mask {
                RoundedRectangle(cornerRadius: 8)
            }
            .onTapGesture(count: 5) {
                onClearAction = true
            }
    }
}

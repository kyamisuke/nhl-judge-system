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
            .frame(width: getSize(), height: getSize())
            .mask {
                RoundedRectangle(cornerRadius: 8)
            }
            .onTapGesture(count: 5) {
                onClearAction = true
            }
    }
    
    private func getSize() -> CGFloat {
        if UIDevice.current.isiPad {
            return 48
        } else if UIDevice.current.isiPhone {
            return 32
        } else {
            return 48
        }
    }
}

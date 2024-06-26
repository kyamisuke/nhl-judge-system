//
//  PrincipalIcon.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/31.
//

import SwiftUI

struct ClearablePrincipalIcon: View {
    @Binding var alertType: AlertType?
    
    var body: some View {
        principalIcon()
    }
    
    private func principalIcon() -> some View {
        Image("icon")
            .resizable()
            .scaledToFill()
            .frame(width: 48, height: 48)
//            .clipShape(Circle())
            .mask {
                RoundedRectangle(cornerRadius: 8)
            }
            .onTapGesture(count: 5) {
                alertType = .onClear
            }
    }
}

struct PrincipalIcon: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        principalIcon()
    }
    
    private func principalIcon() -> some View {
        Image("icon")
            .resizable()
            .scaledToFill()
            .frame(width: 48, height: 48)
//            .clipShape(Circle())
            .mask {
                RoundedRectangle(cornerRadius: 8)
            }
            .onTapGesture(count: 5) {
                dismiss()
            }
    }
}

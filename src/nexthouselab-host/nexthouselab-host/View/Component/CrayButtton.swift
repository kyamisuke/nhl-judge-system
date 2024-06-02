//
//  CrayButtton.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/06/02.
//

import SwiftUI

struct CrayButtton: View {
    let label: String
    let hue: Double
    let radius: CGFloat
    let action:() -> Void
    
    init(label: String, hue: Double, radius: CGFloat, action: @escaping () -> Void) {
        self.label = label
        self.hue = hue
        self.radius = radius
        self.action = action
    }

    var body: some View {
        Button(action: action, label: {
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(
                            // shadowでボタン上部に光沢を持たせる
                            // .innerはiOS16から対応
                            .shadow(.inner(color: Color(hue: hue, saturation: 0.3, brightness: 1), radius: 6, x: 4, y: 4))
                            // shadowでボタン下部に影を落とす
                                .shadow(.inner(color: Color(hue: hue, saturation: 0.8, brightness: 0.8), radius: 6, x: -2, y: -2))
                        )
                        .foregroundColor(Color(hue: hue, saturation: 0.6, brightness: 1))
                )
        })
    }
}

//
//  CrayButtonView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/06/01.
//

import SwiftUI

struct CrayButtonView: View {
    let label: String
    let action:() -> Void
    let lightColor: Color
    let shadowColor: Color
    let buttonColor: Color
    let radius: CGFloat
    let fontSize: CGFloat
    
    var body: some View {
        Button(action: action, label: {
            Text(label)
                .font(.system(size: fontSize, weight: .semibold, design: .default))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: radius)
                        .fill(
                            // shadowでボタン上部に光沢を持たせる
                            // .innerはiOS16から対応
                            .shadow(.inner(color: lightColor, radius: 6, x: 4, y: 4))
                            // shadowでボタン下部に影を落とす
                                .shadow(.inner(color: shadowColor, radius: 6, x: -2, y: -2))
                        )
                        .foregroundColor(buttonColor)
                )
        })
    }
}

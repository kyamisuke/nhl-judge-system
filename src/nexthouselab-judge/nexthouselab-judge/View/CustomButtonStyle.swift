//
//  CustomButtonStyle.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/06/08.
//

import SwiftUI

// カスタムスタイルの定義
struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .background {
                RoundedRectangle(
                    cornerSize: .init(width: 8, height: 8),
                    style: .continuous
                )
                .fill(.tint)    // .fill(.tint)に変更すると便利
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// .buttonStyleで指定できるようにする
extension ButtonStyle where Self == CustomButtonStyle {
    static var custom: CustomButtonStyle {
        CustomButtonStyle()
    }
}

//
//  TrackableList.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/09.
//

import SwiftUI

struct TrackableList<Content>: View where Content: View {
    @Binding var contentOffset: CGFloat
    let content: Content

    init(contentOffset: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._contentOffset = contentOffset
        self.content = content()
    }

    var body: some View {
        GeometryReader { outsideProxy in
            List {
                ZStack {
                    GeometryReader { insideProxy in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: [outsideProxy.frame(in: .global).minY - insideProxy.frame(in: .global).minY])
                            // Send value to the parent
                    }
                    VStack {
                        self.content
                    }
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                self.contentOffset = value[0]
            }
            // Get the value then assign to offset binding
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = [CGFloat]

    static var defaultValue: [CGFloat] = [0]

    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
    }
}

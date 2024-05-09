//
//  ScrollToRow.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/09.
//

import SwiftUI

struct ScrollViewToRow: View {
    
    @State private var scrollPosition: Int? = 0
    
    var body: some View {
        
        VStack {
            
            Text("currently at \(scrollPosition ?? -1)")
            
            Button("Scroll") {
                withAnimation {
                    scrollPosition = 10
                }
            }
            
            ScrollView {
                ForEach(1..<30, id: \.self) { number in
                    HStack {
                        Text(verbatim: number.formatted())
                        Spacer()
                    }
                    .padding()
                    .foregroundStyle(.white)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.teal)
                    }
                }
                    .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollPosition)
            
        }
        .padding()
        
    }
    
}

#Preview {
    ScrollViewToRow()
}

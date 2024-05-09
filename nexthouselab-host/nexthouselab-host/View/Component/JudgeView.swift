//
//  JudgeView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI

struct JudgeName: Identifiable, Hashable {
    var id = UUID()
    var name: String
}

struct JudgeView: View {
    @Binding var judgeName: JudgeName
    @Binding var entryMembers: [EntryName]
    @Binding var offset: Int?
    @Binding var currentNumber: Int
    
    var body: some View {
        VStack {
//            Text("offset: \(offsetWithId.offset!), id: \(id)")
            Text(judgeName.name)
                .frame(maxWidth: .infinity)
                .font(.title)
            
            Divider()
            // 角ジャッジの下に表示するエントリーリスト
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(entryMembers) { member in
                        EntryListItemView(entryName: member, currentNumber: $currentNumber)
                            .frame(height: 40)
                    }
                    // id指定でコードから各リストに直接飛べるように仕込む
                    .scrollTargetLayout()
                }
            }
            .scrollPosition(id: $offset)
            .coordinateSpace(name: "ScrollView")
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var entryMembers = [EntryName(number: 1, name: "kyami"), EntryName(number: 2, name: "amazon"), EntryName(number: 3, name: "Amazon")]
        @State var judgeName = JudgeName(name: "KAZANE")
        @State var judgeName2 = JudgeName(name: "HIRO")

        @State var offset: Int? = 0

        var body: some View {
//            Text("offset: \(offset!)")
            HStack {
                JudgeView(judgeName: $judgeName, entryMembers: $entryMembers, offset: $offset, currentNumber: .constant(1))
                JudgeView(judgeName: $judgeName2, entryMembers: $entryMembers, offset: $offset, currentNumber: .constant(1))
            }
        }
    }
    
    return PreviewView()
}

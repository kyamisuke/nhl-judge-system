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
    
    var body: some View {
        VStack {
            //            Section(content: {
            //                List(entryMembers) { member in
            //                    EntryListItemView(entryName: member)
            //                }
            //            }, header: {
            //                Text(judgeName.name)
            //                    .frame(maxWidth: .infinity)
            //                    .font(.title)
            //            })
//            Text("offset: \(offsetWithId.offset!), id: \(id)")
            Text(judgeName.name)
                .frame(maxWidth: .infinity)
                .font(.title)
//            ScrollView {
//                LazyVStack(spacing: 0) {
//                    ForEach(entryMembers) { member in
//                        EntryListItemView(entryName: member)
//                            .frame(height: 40)
//                    }
//                }
//                .background {
//                    GeometryReader { proxy in
//                        Color.clear.onChange(of: proxy.frame(in: .named("ScrollView")).minY) { _, offset in
//                            self.offsetWithId = (-1 * Int(offset / 40), self.id)
//                        }
//                    }
//                }
//            }
//            .coordinateSpace(name: "ScrollView")
//            
//            Button("Scroll") {
//                withAnimation {
//                    offsetWithId.offset = 10
//                }
//            }
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(1..<100, id: \.self) { number in
                        EntryListItemView(entryName: EntryName(number: number, name: "kyami"))
                            .frame(height: 40)
                        //                        .background {
                        //                            RoundedRectangle(cornerRadius: 10)
                        //                                .foregroundStyle(.teal)
                        //                        }
                    }
                    .scrollTargetLayout()
                }
//                .background {
//                    GeometryReader { proxy in
//                        Color.clear.onChange(of: proxy.frame(in: .named("ScrollView")).minY) { _, offset in
//                            //withAnimation {
//                                self.offsetWithId = (-1 * Int(offset / 40), self.id)
//                            //}
//                        }
//                    }
//                }
            }
            .scrollPosition(id: $offset)
            .coordinateSpace(name: "ScrollView")
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var entryMembers = [EntryName(number: 0, name: "kyami"), EntryName(number: 1, name: "amazon"), EntryName(number: 2, name: "Amazon")]
        @State var judgeName = JudgeName(name: "KAZANE")
        @State var judgeName2 = JudgeName(name: "HIRO")

        @State var offset: Int? = 0

        var body: some View {
//            Text("offset: \(offset!)")
            HStack {
                JudgeView(judgeName: $judgeName, entryMembers: $entryMembers, offset: $offset)
                JudgeView(judgeName: $judgeName2, entryMembers: $entryMembers, offset: $offset)
            }
        }
    }
    
    return PreviewView()
}

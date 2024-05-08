//
//  JudgeView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI

struct JudgeName: Identifiable {
    var id = UUID()
    var name: String
}

struct JudgeView: View {
    @Binding var judgeName: JudgeName
    @Binding var entryMembers: [EntryName]
    
    var body: some View {
        VStack {
            Section(content: {
                List(entryMembers) { member in
                    EntryListItemView(entryName: member)
                }
            }, header: {
                Text(judgeName.name)
                    .frame(maxWidth: .infinity)
                    .font(.title)
            })
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var entryMembers = [EntryName(number: 0, name: "kyami"), EntryName(number: 1, name: "amazon"), EntryName(number: 2, name: "Amazon")]
        @State var judgeName = JudgeName(name: "KAZANE")

        var body: some View {
            JudgeView(judgeName: $judgeName, entryMembers: $entryMembers)
        }
    }
    
    return PreviewView()
}

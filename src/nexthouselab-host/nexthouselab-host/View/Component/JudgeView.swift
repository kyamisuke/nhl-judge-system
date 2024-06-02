//
//  JudgeView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI

struct JudgeView: View {
    @Binding var entryMembers: [EntryName]
    @Binding var offset: CGFloat
    @Binding var currentNumber: Int
    @State var isSticky = false
    @Binding var currentMessage: Message
    
    @EnvironmentObject var scoreModel: ScoreModel
    @EnvironmentObject var socketManager: SocketManager
        
    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack {
                        TopUIGrroupView(entryMembers: $entryMembers)
                        Spacer()
                        Divider()
                        Spacer()
                        HStack {
                            Divider()
                            ForEach(Const.JUDGE_NAMES) { judgeName in
                                // 角ジャッジの下に表示するエントリーリスト
                                LazyVStack(spacing: 0) {
                                    Text(judgeName.name)
                                        .frame(maxWidth: .infinity)
                                        .font(.title)
                                        .fontWeight(.bold)
                                    Divider()
                                        .padding(8)
                                    ForEach(entryMembers) { member in
                                        EntryListItemView(entryName: member, currentNumber: $currentNumber, judgeName: judgeName.name, currentMessage: $currentMessage)
                                        Divider()
                                    }
                                }
                                Divider()
                            }
                        }
                        .background {
                            GeometryReader { proxy in
                                Color.clear.onChange(of: proxy.frame(in: .named("ScrollView")).minY) { _, offset in
                                    self.offset = offset
                                }
                            }
                        }
                    }
                }
                //.scrollPosition(id: $offset)
                .coordinateSpace(name: "ScrollView")
                
                // 一定量スクロールしたら表示するラベル
                VStack {
                    HStack {
                        Spacer()
                        Divider()
                        ForEach(Const.JUDGE_NAMES) { judgeName in
                            Text(judgeName.name)
                                .frame(maxWidth: .infinity)
                                .font(.title)
                                .fontWeight(.bold)
                                .background(.white)
                                .opacity(-1 * (offset/80.0 + 1.0))
                            Divider()
                        }
                        Spacer()
                    }
                    .frame(height: 64)
                    Divider()
                }
                .background(.white)
                .opacity(-1 * (offset/80.0 + 1.0))
            }
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var entryMembers = [EntryName]()
        let judgeNames = [JudgeName(name: "KAZANE"), JudgeName(name: "HIRO"), JudgeName(name: "HIRO"), JudgeName(name: "HIRO")]
        
        @State var offset: CGFloat = 0
        
        @StateObject var socketManager = SocketManager()
        @StateObject var scoreModel = ScoreModel()

        var body: some View {
            //            Text("offset: \(offset!)")
            HStack {
                JudgeView(entryMembers: $entryMembers, offset: $offset, currentNumber: .constant(1), currentMessage: .constant(Message(judgeName: "KAZANE", number: 1)))
                    .environmentObject(socketManager)
                    .environmentObject(scoreModel)
            }
            .onAppear {
                for i in 1...100 {
                    entryMembers.append(EntryName(number: i, name: "kyami"))
                }
            }
        }
    }
    
    return PreviewView()
}

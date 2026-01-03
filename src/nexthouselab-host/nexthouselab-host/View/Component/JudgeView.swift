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
    @Binding var isModal: Bool
    @Binding var mode: Const.Mode
    
    @EnvironmentObject var scoreModel: ScoreModel
    @EnvironmentObject var peerManager: PeerManager
    
    var body: some View {
        VStack {
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack {
                        TopUIGrroupView(entryMembers: $entryMembers, isModal: $isModal)
                        Spacer()
                        Divider()
                        Spacer()
                        HStack {
                            Divider()
                            ForEach(Const.JUDGE_NAMES) { judgeName in
                                // 角ジャッジの下に表示するエントリーリスト
                                Text(judgeName.name)
                                    .frame(maxWidth: .infinity)
                                    .font(.title)
                                    .fontWeight(.bold)
                                Button(action: {
                                    sendUpdateRequest()
                                }, label: {
                                    Text("更新")
                                })
                                .buttonStyle(.custom)
                                Divider()
                                
                            }
                        }
                        Divider()
                        ForEach(entryMembers) { member in
                            HStack {
                                Divider()
                                ForEach(Const.JUDGE_NAMES) { judgeName in
                                    EntryListItemView(entryName: member, currentNumber: $currentNumber, judgeName: judgeName.name, currentMessage: $currentMessage, mode: $mode)
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
                //.scrollPosition(id: $offset)
                .coordinateSpace(name: "ScrollView")
                
                // 一定量スクロールしたら表示するラベル
                VStack {
                    HStack {
                        Divider()
                        ForEach(Const.JUDGE_NAMES) { judgeName in
                            Text(judgeName.name)
                                .frame(maxWidth: .infinity)
                                .font(.title)
                                .fontWeight(.bold)
                                .background(.clear)
                                .opacity(getOffset())
                            Button(action: {
                                sendUpdateRequest()
                            }, label: {
                                Text("更新")
                            })
                            .buttonStyle(.custom)
                            Divider()
                        }
                    }
                    .frame(height: 48)
                    Divider()
                }
                .background(
                    Rectangle()
                        .foregroundStyle(.ultraThinMaterial)
                        .shadow(color: .init(white: 0.4, opacity: 0.4), radius: 5, x: 0, y: 0)
                )
                .opacity(getOffset())
            }
        }
    }
    
    private func sendUpdateRequest() {
        peerManager.send(message: NetworkMessage.requestUpdate)
        print("🔄 UPDATE ブロードキャスト送信")
    }
    
    private func getOffset() -> CGFloat {
        return clamp(from: 0, to: 1, in: -1 * (offset/40.0 + 1.0))
    }
    
    private func clamp(from minV: CGFloat, to maxV: CGFloat, in value: CGFloat) -> CGFloat {
        return min(max(value, 0), 1)
    }
}

#Preview {
    struct PreviewView: View {
        @State var entryMembers = [EntryName]()
        let judgeNames = [JudgeName(name: "KAZANE"), JudgeName(name: "HIRO"), JudgeName(name: "HIRO"), JudgeName(name: "HIRO")]
        
        @State var offset: CGFloat = 0
        
        @StateObject var peerManager = PeerManager()
        @StateObject var scoreModel = ScoreModel()
        
        var body: some View {
            //            Text("offset: \(offset!)")
            HStack {
                JudgeView(entryMembers: $entryMembers, offset: $offset, currentNumber: .constant(1), currentMessage: .constant(Message(judgeName: "KAZANE", number: 1)), isModal: .constant(false), mode: .constant(.solo))
                    .environmentObject(peerManager)
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

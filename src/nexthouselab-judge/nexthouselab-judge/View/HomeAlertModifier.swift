//
//  HomeAlertModifier.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/31.
//

import SwiftUI

struct HomeAlertModifier: ViewModifier {
    @Binding var alertType: AlertType?
    @Binding var isChecked: Bool
    @EnvironmentObject var scoreModel: ScoreModel
    @Binding var shouldInitialize: Bool
    @Binding var navigateToMainView: Bool
    @EnvironmentObject var socketManager: SocketManager
    @Binding var hostIp: String
    
    func body(content: Content) -> some View {
        content
            .alert(item: $alertType) { alertType in
                switch alertType {
                case .nameError:
                    return Alert(
                        title: Text("ジャッジの名前が入力されていません。"),
                        message: Text("ジャッジの名前が入力されていることを確認してください。"),
                        dismissButton: .default(Text("戻る"))
                    )
                case .fileError:
                    return Alert(
                        title: Text("エントリーリストが選択されていません。"),
                        message: Text("ファイルを選択し、エントリーリストを設定してください。"),
                        dismissButton: .default(Text("戻る"))
                    )
                case .scoreData:
                    return Alert(
                        title: Text("前回のデータが残っています"),
                        message: Text("前回中断したデータを復元しますか？キャンセルした場合、前回のデータは復元できません。"),
                        primaryButton: .default(Text("復元"), action: {
                            isChecked = true
                            scoreModel.update(scores: UserDefaults.standard.dictionary(forKey: "scores") as! Dictionary<String, Float>)
                            shouldInitialize = false
                            navigateToMainView = true
                            DispatchQueue.global(qos: .background).async {
                                socketManager.connect(host: hostIp, port: "9000", param: .udp)
                                socketManager.startListener(name: "judge_listner")
                            }
                        }),
                        secondaryButton: .cancel(Text("キャンセル"), action: {
                            isChecked = true
                            UserDefaults.standard.set(nil, forKey: "scores")
                        })
                    )
                }
            }
    }
}

//
//  HomeAlertModifier.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/31.
//

import SwiftUI

enum AlertType: Identifiable {
    case nameError
    case fileError
    case scoreData
    case onClear
    var id: AlertType { self }
}

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
                        message: Text("前回中断したデータから再開しますか？"),
                        primaryButton: .default(Text("再開"), action: {
                            isChecked = true
                            scoreModel.update(scores: UserDefaults.standard.dictionary(forKey: "scores") as! Dictionary<String, Float>)
                            shouldInitialize = false
                            navigateToMainView = true
                        }),
                        secondaryButton: .cancel(Text("キャンセル"), action: {
                            isChecked = true
                        })
                    )
                case .onClear:
                    return Alert(
                        title: Text("得点のデータを初期化しますか？"),
                        message: Text("初期化したデータは復元できません。"),
                        primaryButton: .destructive(Text("削除"), action: {
                            UserDefaults.standard.set(nil, forKey: "scores")
                            shouldInitialize = true
                        }),
                        secondaryButton: .cancel(Text("キャンセル"))
                    )
                }
            }
    }
}

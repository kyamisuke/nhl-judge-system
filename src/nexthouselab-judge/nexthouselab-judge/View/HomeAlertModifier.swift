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

    var title: String {
        switch self {
        case .nameError:
            return "ジャッジの名前が入力されていません。"
        case .fileError:
            return "エントリーリストが選択されていません。"
        default:
            return ""
        }
    }

    var message: String {
        switch self {
        case .nameError:
            return "ジャッジの名前が入力されていることを確認してください。"
        case .fileError:
            return "ファイルを選択し、エントリーリストを設定してください。"
        default:
            return ""
        }
    }

}

struct HomeAlertModifier: ViewModifier {
    @Binding var alertType: AlertType?
    @Binding var isChecked: Bool
    @EnvironmentObject var scoreModel: ScoreModel
    @Binding var shouldInitialize: Bool
    @Binding var navigateToMainView: Bool
    @Binding var hostIp: String
    @Binding var currentPlayNum: Int
    
    func body(content: Content) -> some View {
        content
            .alert(item: $alertType) { alertType in
                switch alertType {
                case .nameError, .fileError:
                    return Alert(
                        title: Text(alertType.title),
                        message: Text(alertType.message),
                        dismissButton: .default(Text("戻る"))
                    )
                case .scoreData:
                    return Alert(
                        title: Text("前回のデータが残っています"),
                        message: Text("前回中断したデータから再開しますか？"),
                        primaryButton: .default(Text("再開"), action: {
                            isChecked = true
                            // ScoreModelはinit時にUserDefaultsから自動的に読み込むため、
                            // ここでは読み込み不要（既にloadFromUserDefaults()が呼ばれている）
                            currentPlayNum = UserDefaults.standard.integer(forKey: AppConfiguration.StorageKeys.currentPlayNum)
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
                            UserDefaults.standard.set(nil, forKey: AppConfiguration.StorageKeys.scores)
                            UserDefaults.standard.set(nil, forKey: AppConfiguration.StorageKeys.doneStates)
                            currentPlayNum = 1
                            shouldInitialize = true
                        }),
                        secondaryButton: .cancel(Text("キャンセル"))
                    )
                }
            }
    }
}

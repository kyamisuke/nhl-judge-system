//
//  AppConfiguration.swift
//  nexthouselab-judge
//
//  アプリケーション設定の一元管理
//

import SwiftUI

/// アプリケーション全体の設定を管理する構造体
struct AppConfiguration {

    // MARK: - Network Configuration

    struct Network {
        /// MultipeerConnectivityのサービスタイプ
        static let serviceType = "judge-session"
        /// セッション表示名
        static let sessionName = "NHL Judge Session"
    }

    // MARK: - UserDefaults Keys

    struct StorageKeys {
        static let selectedFileContents = "selected_file_cocntents"
        static let fileName = "file_name"
        static let judgeName = "judge_name"
        static let scores = "scores"
        static let doneStates = "done_states"
        static let currentPlayNum = "current_play_num_key"
        // 注: IP関連のキー(hostIP, host)は削除されました
        // MultipeerConnectivityでは自動検出を使用します
    }

    // MARK: - Score Configuration

    struct Scores {
        /// スコアの最小値
        static let minValue: Float = 0
        /// スコアの最大値
        static let maxValue: Float = 10
        /// スコアのステップ
        static let step: Float = 0.5
        /// スコアスライダーの目盛り数
        static let tickCount: Int = 21
        /// 自動保存の間隔（秒）
        static let autoSaveInterval: TimeInterval = 5.0
    }

    // MARK: - Competition Modes

    enum CompetitionMode: String, CaseIterable, Identifiable {
        case solo = "Solo"
        case dual = "Dual"

        var id: String { self.rawValue }

        /// モードごとのプレイヤー数
        var playerCount: Int {
            switch self {
            case .solo:
                return 1
            case .dual:
                return 2
            }
        }

        /// 後方互換性のためのメソッド
        func playerNum() -> Int {
            return playerCount
        }
    }

    // MARK: - Export Genres

    struct ExportGenres {
        static let genres = ["Hiphop", "Poppin", "Lockin", "House"]
    }

    // MARK: - UI Constants

    struct UI {
        /// ボタンの角丸半径
        static let buttonRadius: CGFloat = 12
        /// フレーム幅の標準サイズ
        static let standardFrameWidth: CGFloat = 480
        /// 小さなフレーム幅
        static let smallFrameWidth: CGFloat = 150
        /// 中程度のフレーム幅
        static let mediumFrameWidth: CGFloat = 400

        /// 日本語ロケールのボタンフォントサイズ
        static let japaneseButtonFontSize: CGFloat = 16
        /// 英語ロケールのボタンフォントサイズ
        static let englishButtonFontSize: CGFloat = 12
    }
}

// MARK: - Legacy Compatibility

/// 後方互換性のための定数クラス
/// 既存コードとの互換性を保つため、AppConfigurationへの参照を提供
class Const {
    // UserDefaults Keys
    static let SELCTED_FILE_KEY = AppConfiguration.StorageKeys.selectedFileContents
    static let FILE_NAME_KEY = AppConfiguration.StorageKeys.fileName
    static let JUDGE_NAME_KEY = AppConfiguration.StorageKeys.judgeName
    static let SCORE_KEY = AppConfiguration.StorageKeys.scores
    static let DONE_STATES_KEY = AppConfiguration.StorageKeys.doneStates
    static let CURRENT_PLAY_NUM_KEY = AppConfiguration.StorageKeys.currentPlayNum

    // Mode Type Alias
    typealias Mode = AppConfiguration.CompetitionMode
}

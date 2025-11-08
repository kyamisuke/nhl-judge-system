//
//  AppConfiguration.swift
//  nexthouselab-host
//
//  アプリケーション設定の一元管理
//

import SwiftUI

/// アプリケーション全体の設定を管理する構造体
struct AppConfiguration {

    // MARK: - Network Configuration

    struct Network {
        static let hostPort: UInt16 = 9000
        static let judgePort: UInt16 = 8000
        static let serviceType = "_networkplayground._udp."
        static let networkDomain = "local"
    }

    // MARK: - UserDefaults Keys

    struct StorageKeys {
        static let selectedFileContents = "selected_file_cocntents"
        static let fileName = "file_name"
        static let ipAddress = "ip_key"
        static let hostAddresses = "host_key"
        static let scores = "scores"
    }

    // MARK: - Judge Configuration

    struct Judges {
        /// デフォルトの審査員名リスト
        static let defaultNames = [
            JudgeName(name: "Judge1"),
            JudgeName(name: "Judge2"),
            JudgeName(name: "Judge3"),
            JudgeName(name: "Judge4")
        ]

        /// 審査員の数（将来的に動的変更可能にする）
        static var count: Int {
            return defaultNames.count
        }
    }

    // MARK: - UI Colors

    struct Colors {
        static let exportButton = Color("exportButton")
        static let importButton = Color("importButton")
        static let judgeLabel = Color(hue: 0, saturation: 0, brightness: 0.9)
        static let oddRow = Color("oddColor")
        static let evenRow = Color("evenColor")
        static let exported = Color("isExported")
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
}

// MARK: - Legacy Compatibility

/// 後方互換性のための定数クラス
/// 既存コードとの互換性を保つため、AppConfigurationへの参照を提供
class Const {
    // UserDefaults Keys
    static let SELCTED_FILE_KEY = AppConfiguration.StorageKeys.selectedFileContents
    static let FILE_NAME_KEY = AppConfiguration.StorageKeys.fileName
    static let IP_KEY = AppConfiguration.StorageKeys.ipAddress
    static let HOST_KEY = AppConfiguration.StorageKeys.hostAddresses
    static let SCORES_KEY = AppConfiguration.StorageKeys.scores

    // Judge Configuration
    static let JUDGE_NAMES = AppConfiguration.Judges.defaultNames

    // Colors
    static let exportColor = AppConfiguration.Colors.exportButton
    static let importColor = AppConfiguration.Colors.importButton
    static let judgeLabelColor = AppConfiguration.Colors.judgeLabel

    // Mode Type Alias
    typealias Mode = AppConfiguration.CompetitionMode
}

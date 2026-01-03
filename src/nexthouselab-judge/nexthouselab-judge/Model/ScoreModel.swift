//
//  ScoreModel.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/23.
//

import Foundation
import SwiftUI
import Combine

final public class ScoreModel: ObservableObject {
    @Published var scores: Dictionary<String, Float?>
    @Published var doneArray: Dictionary<String, Bool>
    @Published var updatedTime: String = ""

    private var timer: Timer?
    private let formatter: DateFormatter = DateFormatter()

    init() {
        scores = Dictionary<String, Float?>()
        doneArray = Dictionary<String, Bool>()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMdkHms", options: 0, locale: Locale(identifier: "ja_JP"))

        // 保存されたデータを読み込み
        loadFromUserDefaults()
    }
    
    /// エントリーリストで初期化（既存のスコアは保持）
    func initialize(entryList: [EntryName], preserveExistingScores: Bool = false) {
        for entry in entryList {
            let key = String(entry.number)
            if preserveExistingScores {
                // 既存のスコアがない場合のみ追加
                if !scores.keys.contains(key) {
                    // nilを値として設定（dict[key] = nilはキー削除になるため updateValue を使用）
                    scores.updateValue(nil, forKey: key)
                }
                if !doneArray.keys.contains(key) {
                    doneArray[key] = false
                }
            } else {
                // nilを値として設定（dict[key] = nilはキー削除になるため updateValue を使用）
                scores.updateValue(nil, forKey: key)
                doneArray[key] = false
            }
        }
    }

    func getScore(for key: String) -> Binding<Float> {
        return .init(
            get: { self.scores[key, default: nil] ?? 0 },
            set: { self.scores[key] = $0 }
        )
    }

    func getDoneState(for key: String) -> Binding<Bool> {
        return .init(
            get: { self.doneArray[key, default: false] },
            set: { self.doneArray[key] = $0 }
        )
    }

    func updateDoneState(in key: String, value: Bool) {
        doneArray[key] = value
    }

    func updateDoneState(_ value: Dictionary<String, Bool>) {
        doneArray = value
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: AppConfiguration.Scores.autoSaveInterval, repeats: true) { [weak self] _ in
            self?.saveToUserDefaults()
        }
    }

    /// UserDefaultsにデータを保存
    private func saveToUserDefaults() {
        // Float?をFloatに変換（nilは-1に変換して後方互換性を維持）
        var rawScores = [String: Float]()
        for (key, value) in scores {
            rawScores[key] = value ?? -1
        }

        UserDefaults.standard.set(rawScores, forKey: AppConfiguration.StorageKeys.scores)
        UserDefaults.standard.set(doneArray, forKey: AppConfiguration.StorageKeys.doneStates)
        updatedTime = formatter.string(from: Date())
        print("💾 Auto-saved scores at \(updatedTime)")
    }

    /// UserDefaultsからデータを読み込み
    private func loadFromUserDefaults() {
        if let rawScores = UserDefaults.standard.dictionary(forKey: AppConfiguration.StorageKeys.scores) as? [String: Float] {
            // -1をnilに変換（dict[key] = nilはキー削除になるため updateValue を使用）
            for (key, value) in rawScores {
                if value == -1 {
                    scores.updateValue(nil, forKey: key)
                } else {
                    scores[key] = value
                }
            }
            print("📂 Loaded \(rawScores.count) scores from storage")
        }

        if let states = UserDefaults.standard.dictionary(forKey: AppConfiguration.StorageKeys.doneStates) as? [String: Bool] {
            doneArray = states
            print("📂 Loaded \(states.count) done states from storage")
        }
    }

    func stopTimer() {
        timer?.invalidate()
    }
}

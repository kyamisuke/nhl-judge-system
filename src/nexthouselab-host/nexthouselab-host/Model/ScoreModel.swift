//
//  Model.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/31.
//

import SwiftUI

final public class ScoreModel: ObservableObject {
    @Published var scores: Dictionary<String, Dictionary<String, Float?>>
    @Published var updatedTime: String = ""

    private var timer: Timer?
    private let formatter: DateFormatter = DateFormatter()

    init() {
        scores = Dictionary<String, Dictionary<String, Float?>>()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMdkHms", options: 0, locale: Locale(identifier: "ja_JP"))
    }

    func initialize(entryNames: [EntryName]) {
        if let storedScore = UserDefaults.standard.object(forKey: Const.SCORES_KEY) as? Dictionary<String, Dictionary<String, Float>> {
            // 既存データを変換: -1 を nil に変換
            scores = Dictionary<String, Dictionary<String, Float?>>()
            for (judgeName, judgeScores) in storedScore {
                var convertedScores = Dictionary<String, Float?>()
                for (entryNumber, score) in judgeScores {
                    convertedScores[entryNumber] = score == -1 ? nil : score
                }
                scores[judgeName] = convertedScores
            }
            print("すでにデータが存在しています。")
        } else {
            scores = Dictionary<String, Dictionary<String, Float?>>()
            for judgeName in Const.JUDGE_NAMES {
                var tmpScores = Dictionary<String, Float?>()
                for entryName in entryNames {
                    tmpScores[String(entryName.number)] = nil
                }
                scores[judgeName.name] = tmpScores
            }
            print("Initialize score.")
        }
    }

    func getScore(in judgeName: String, for key: String) -> Binding<Float?> {
        return .init(
            get: { (self.scores[judgeName] ?? Dictionary<String, Float?>())[key, default: nil] },
            set: { self.scores[judgeName]?[key] = $0 }
        )
    }

    /// Float版の互換性のための関数（従来の-1を返す）
    func getScoreLegacy(in judgeName: String, for key: String) -> Float {
        return getScore(in: judgeName, for: key).wrappedValue ?? -1
    }

    func update(forKey judge: String, scores: Dictionary<String, Float>) {
        // Float版をOptional版に変換
        var convertedScores = Dictionary<String, Float?>()
        for (key, value) in scores {
            convertedScores[key] = value == -1 ? nil : value
        }
        self.scores[judge] = convertedScores
    }

    func updateOptional(forKey judge: String, scores: Dictionary<String, Float?>) {
        self.scores[judge] = scores
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveCounter()
        }
    }
    
    private func saveCounter() {
        // Optional<Float>をFloatに変換して保存（互換性のため）
        var legacyScores = Dictionary<String, Dictionary<String, Float>>()
        for (judgeName, judgeScores) in scores {
            var convertedScores = Dictionary<String, Float>()
            for (entryNumber, score) in judgeScores {
                convertedScores[entryNumber] = score ?? -1
            }
            legacyScores[judgeName] = convertedScores
        }
        UserDefaults.standard.set(legacyScores, forKey: Const.SCORES_KEY)
        updatedTime = formatter.string(from: Date())
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
}

final public class JudgeIpModel: ObservableObject {
    var judgeAndIpDic: [String: String]
    @Published var keys: [String]
    
    init() {
        if let data = UserDefaults.standard.dictionary(forKey: Const.HOST_KEY) as? [String: String] {
            judgeAndIpDic = data
            keys = data.map { $0.key }
        } else {
            judgeAndIpDic = [String: String]()
            keys = [String]()
        }
    }
    
    func update(forKey judge: String, value ip: String) -> Bool {
        if keys.contains(judge) {
            return false
        } else if judgeAndIpDic.map({ $0.value }).contains(ip) {
            return false
        } else {
            judgeAndIpDic[judge] = ip
            keys.append(judge)
            save()
            return true
        }
    }
    
    func remove(forKey judge: String) -> Bool {
        if keys.contains(judge) {
            let i = keys.firstIndex(of: judge)!
            let _ = keys.remove(at: i)
            let _ = judgeAndIpDic.removeValue(forKey: judge)
            save()
            return true
        } else {
            return false
        }
    }
    
    private func save() {
        UserDefaults.standard.set(judgeAndIpDic, forKey: Const.HOST_KEY)
    }
    
    func getIp(forKey judge: String) -> String? {
        return judgeAndIpDic[judge]
    }
}

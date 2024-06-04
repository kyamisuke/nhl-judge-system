//
//  Model.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/31.
//

import SwiftUI

final public class ScoreModel: ObservableObject {
    @Published var scores: Dictionary<String, Dictionary<String, Float>>
    @Published var udpatedTime: String = ""
    
    private var timer: Timer?
    private let formatter: DateFormatter = DateFormatter()
    
    init() {
        scores = Dictionary<String, Dictionary<String, Float>>()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMdkHms", options: 0, locale: Locale(identifier: "ja_JP"))
    }
    
    func initialize(entryNames: [EntryName]) {
        let storedScore = UserDefaults.standard.object(forKey: Const.SCORES_KEY) as? Dictionary<String, Dictionary<String, Float>>
        if storedScore == nil {
            scores = Dictionary<String, Dictionary<String, Float>>()
            for judgeName in Const.JUDGE_NAMES {
                var tmpScores = Dictionary<String, Float>()
                for entryName in entryNames {
                    tmpScores[String(entryName.number)] = -1
                }
                scores[judgeName.name] = tmpScores
            }
            print("Initialze score.")
        } else {
            scores = storedScore!
            print("すでにデータが存在しています。")
        }
    }
    
    func getScore(in judgeName: String, for key: String) -> Binding<Float> {
        return .init(
            get: { (self.scores[judgeName] ?? Dictionary<String, Float>())[key, default: -1] },
            set: { self.scores[judgeName]?[key] = $0 }
        )
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveCounter()
        }
    }
    
    private func saveCounter() {
        UserDefaults.standard.set(scores, forKey: Const.SCORES_KEY)
        udpatedTime = formatter.string(from: Date())
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
}

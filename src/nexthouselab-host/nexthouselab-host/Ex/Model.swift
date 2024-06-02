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
        let storedScore = UserDefaults.standard.object(forKey: "scores") as? Dictionary<String, Dictionary<String, Float>>
        if storedScore == nil {
            scores = Dictionary<String, Dictionary<String, Float>>()
            for judgeName in Const.JUDGE_NAMES {
                var tmpScores = Dictionary<String, Float>()
                for entryName in entryNames {
                    tmpScores[String(entryName.number)] = 0
                }
                scores[judgeName.name] = tmpScores
            }
        } else {
            scores = storedScore!
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveCounter()
        }
    }
    
    private func saveCounter() {
        UserDefaults.standard.set(scores, forKey: "scores")
        udpatedTime = formatter.string(from: Date())
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
}

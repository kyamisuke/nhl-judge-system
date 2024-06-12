//
//  Model.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/23.
//

import Foundation
import SwiftUI
import Combine

final public class ScoreModel: ObservableObject {
    @Published var scores: Dictionary<String, Float>
    @Published var doneArray: Dictionary<String, Bool>
    @Published var udpatedTime: String = ""
    
    private var timer: Timer?
    private let formatter: DateFormatter = DateFormatter()
    
    init() {
        scores = Dictionary<String, Float>()
        doneArray = Dictionary<String, Bool>()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMdkHms", options: 0, locale: Locale(identifier: "ja_JP"))
    }
    
    func initialize(entryList: [EntryName]) {
        for entry in entryList {
            scores[String(entry.number)] = 0
            doneArray[String(entry.number)] = false
        }
    }
    
    func updateScores(_ scores: Dictionary<String, Float>) {
        self.scores = scores
    }
    
    func updateScores(forKey key: String, value: Float) {
        self.scores[key] = value
    }
    
    func getScore(for key: String) -> Binding<Float> {
        return .init(
            get: { self.scores[key, default: -1] },
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
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveCounter()
        }
    }
    
    private func saveCounter() {
        UserDefaults.standard.set(scores, forKey: Const.SCORE_KEY)
        UserDefaults.standard.set(doneArray, forKey: Const.DONE_STATES_KEY)
        udpatedTime = formatter.string(from: Date())
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
}

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
    @Published var udpatedTime: String = ""
    
    private var timer: Timer?
    private let formatter: DateFormatter = DateFormatter()
    
    init() {
        scores = Dictionary<String, Float>()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMdkHms", options: 0, locale: Locale(identifier: "ja_JP"))
    }
    
    func initialize(entryList: [EntryName]) {
        for entry in entryList {
            scores[String(entry.number)] = 0
        }
    }
    
    func update(scores: Dictionary<String, Float>) {
        self.scores = scores
    }
    
    func getScore(for key: String) -> Binding<Float> {
        return .init(
            get: { self.scores[key, default: -1] },
            set: { self.scores[key] = $0 }
        )
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

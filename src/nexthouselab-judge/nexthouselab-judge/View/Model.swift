//
//  Model.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/23.
//

import Foundation
import SwiftUI

final public class ScoreModel: ObservableObject {
    @Published var scores: Dictionary<String, Float>
    
    init() {
        scores = Dictionary<String, Float>()
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
}

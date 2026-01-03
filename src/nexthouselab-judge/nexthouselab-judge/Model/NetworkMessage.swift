//
//  NetworkMessage.swift
//  nexthouselab-judge
//
//  型安全なネットワークメッセージプロトコル
//

import Foundation

/// ネットワーク経由で送受信されるメッセージの型定義
enum NetworkMessage {
    case editing(judgeName: String, entryNumber: Int)
    case decision(judgeName: String, entryNumber: Int, score: Float?)
    case cancel(judgeName: String, entryNumber: Int)
    case update(judgeName: String, scores: [String: Float?], doneStates: [String: Bool])
    case currentNumber(number: Int)
    case requestUpdate

    /// 文字列メッセージをパースしてNetworkMessageに変換
    static func parse(from message: String) -> NetworkMessage? {
        let components = message.components(separatedBy: "/")

        guard !components.isEmpty else { return nil }

        let command = components[0]

        switch command {
        case "EDITING":
            guard components.count >= 3,
                  let entryNumber = Int(components[2]) else {
                return nil
            }
            return .editing(judgeName: components[1], entryNumber: entryNumber)

        case "SCORER":
            guard components.count >= 4 else { return nil }
            let action = components[1]
            let judgeName = components[2]
            guard let entryNumber = Int(components[3]) else { return nil }

            if action == "DECISION" {
                guard components.count >= 5,
                      let scoreValue = Float(components[4]) else {
                    return nil
                }
                // -1 は nil (未入力) として扱う
                let score = scoreValue == -1 ? nil : scoreValue
                return .decision(judgeName: judgeName, entryNumber: entryNumber, score: score)
            } else if action == "CANCEL" {
                return .cancel(judgeName: judgeName, entryNumber: entryNumber)
            }
            return nil

        case "UPDATE":
            if components.count >= 4 {
                // UPDATE/{judgeName}/{scoresJSON}/{doneStatesJSON}
                do {
                    let judgeName = components[1]
                    guard let scoresData = components[2].data(using: .utf8),
                          let statesData = components[3].data(using: .utf8) else {
                        return nil
                    }

                    let rawScores = try JSONSerialization.jsonObject(with: scoresData) as? [String: Float] ?? [:]
                    let doneStates = try JSONSerialization.jsonObject(with: statesData) as? [String: Bool] ?? [:]

                    // スコアをOptional型に変換し、-1とstateがfalseの場合はnilとして扱う
                    var scores = [String: Float?]()
                    for (key, value) in rawScores {
                        if value == -1 || doneStates[key] == false {
                            // dict[key] = nil はキー削除になるため updateValue を使用
                            scores.updateValue(nil, forKey: key)
                        } else {
                            scores[key] = value
                        }
                    }

                    return .update(judgeName: judgeName, scores: scores, doneStates: doneStates)
                } catch {
                    print("Failed to parse UPDATE message: \(error)")
                    return nil
                }
            } else {
                // "UPDATE" のみの場合はリクエスト
                return .requestUpdate
            }

        default:
            // 数値のみのメッセージは現在のエントリー番号として扱う
            if let number = Int(command) {
                return .currentNumber(number: number)
            }
            return nil
        }
    }

    /// NetworkMessageを文字列に変換（送信用）
    func serialize() -> String {
        switch self {
        case .editing(let judgeName, let entryNumber):
            return "EDITING/\(judgeName)/\(entryNumber)"

        case .decision(let judgeName, let entryNumber, let score):
            // nilの場合は-1として送信（後方互換性のため）
            let scoreValue = score ?? -1
            return "SCORER/DECISION/\(judgeName)/\(entryNumber)/\(scoreValue)"

        case .cancel(let judgeName, let entryNumber):
            return "SCORER/CANCEL/\(judgeName)/\(entryNumber)/-1"

        case .update(let judgeName, let scores, let doneStates):
            do {
                // Optional<Float>をFloatに変換（nilは-1に変換）
                var rawScores = [String: Float]()
                for (key, value) in scores {
                    rawScores[key] = value ?? -1
                }

                let scoresData = try JSONSerialization.data(withJSONObject: rawScores)
                let statesData = try JSONSerialization.data(withJSONObject: doneStates)
                guard let scoresJSON = String(data: scoresData, encoding: .utf8),
                      let statesJSON = String(data: statesData, encoding: .utf8) else {
                    return ""
                }
                return "UPDATE/\(judgeName)/\(scoresJSON)/\(statesJSON)"
            } catch {
                print("Failed to serialize UPDATE message: \(error)")
                return ""
            }

        case .currentNumber(let number):
            return "\(number)"

        case .requestUpdate:
            return "UPDATE"
        }
    }
}

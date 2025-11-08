//
//  NetworkMessage.swift
//  nexthouselab-host
//
//  型安全なネットワークメッセージプロトコル
//

import Foundation

/// ネットワーク経由で送受信されるメッセージの型定義
enum NetworkMessage {
    case editing(judgeName: String, entryNumber: Int)
    case connect(ipAddress: String)
    case disconnect(ipAddress: String)
    case scorer(judgeName: String, entryNumber: String, score: Float?)
    case update(judgeName: String, scores: [String: Float?])
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

        case "CONNECT":
            guard components.count >= 2 else { return nil }
            return .connect(ipAddress: components[1])

        case "DISCONNECT":
            guard components.count >= 2 else { return nil }
            return .disconnect(ipAddress: components[1])

        case "SCORER":
            guard components.count >= 5,
                  let scoreValue = Float(components[4]) else {
                return nil
            }
            // -1 は nil (未入力) として扱う
            let score = scoreValue == -1 ? nil : scoreValue
            return .scorer(judgeName: components[2], entryNumber: components[3], score: score)

        case "UPDATE":
            guard components.count >= 4 else { return nil }
            do {
                let judgeName = components[1]
                guard let scoresData = components[2].data(using: .utf8),
                      let statesData = components[3].data(using: .utf8) else {
                    return nil
                }

                let rawScores = try JSONSerialization.jsonObject(with: scoresData) as? [String: Float] ?? [:]
                let states = try JSONSerialization.jsonObject(with: statesData) as? [String: Bool] ?? [:]

                // スコアをOptional型に変換し、-1とstateがfalseの場合はnilとして扱う
                var scores = [String: Float?]()
                for (key, value) in rawScores {
                    if value == -1 || states[key] == false {
                        scores[key] = nil
                    } else {
                        scores[key] = value
                    }
                }

                return .update(judgeName: judgeName, scores: scores)
            } catch {
                print("Failed to parse UPDATE message: \(error)")
                return nil
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

        case .connect(let ipAddress):
            return "CONNECT/\(ipAddress)"

        case .disconnect(let ipAddress):
            return "DISCONNECT/\(ipAddress)"

        case .scorer(let judgeName, let entryNumber, let score):
            // nilの場合は-1として送信（後方互換性のため）
            let scoreValue = score ?? -1
            return "SCORER/\(judgeName)/\(entryNumber)/\(scoreValue)"

        case .update(let judgeName, let scores):
            do {
                // Optional<Float>をFloatに変換（nilは-1に変換）
                var rawScores = [String: Float]()
                var states = [String: Bool]()
                for (key, value) in scores {
                    if let value = value {
                        rawScores[key] = value
                        states[key] = true
                    } else {
                        rawScores[key] = -1
                        states[key] = false
                    }
                }

                let scoresData = try JSONSerialization.data(withJSONObject: rawScores)
                let statesData = try JSONSerialization.data(withJSONObject: states)
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

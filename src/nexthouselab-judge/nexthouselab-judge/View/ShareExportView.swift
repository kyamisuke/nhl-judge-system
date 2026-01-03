//
//  ShareExportView.swift
//  nexthouselab-judge
//
//  Created by Claude on 2025/01/03.
//

import SwiftUI

struct ShareExportView: View {
    @State private var isSharePresented = false
    @State private var csvFileURL: URL?

    @Binding private var sufix: String

    let fileName: String
    @EnvironmentObject var scoreModel: ScoreModel

    init(fileName: String, sufix: Binding<String> = .constant("")) {
        self.fileName = fileName
        _sufix = sufix
    }

    var body: some View {
        Button(action: {
            prepareCSVFile()
        }) {
            Image(systemName: "square.and.arrow.up")
        }
        .buttonStyle(.custom)
        .sheet(isPresented: $isSharePresented) {
            if let url = csvFileURL {
                ActivityViewControllerRepresentable(
                    activityItems: [url],
                    onComplete: { cleanupTemporaryFile() }
                )
            }
        }
    }

    private func prepareCSVFile() {
        let csvData = generateCSVData()

        let csvFileName: String
        if sufix.isEmpty {
            csvFileName = "\(fileName).csv"
        } else {
            csvFileName = "\(fileName)_\(sufix).csv"
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(csvFileName)

        do {
            try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
            csvFileURL = fileURL
            isSharePresented = true
        } catch {
            print("Failed to create temporary CSV file: \(error)")
        }
    }

    private func generateCSVData() -> String {
        var data = ""
        for (number, score) in scoreModel.scores.sorted(by: { Int($0.0)! < Int($1.0)! }) {
            let scoreValue = score ?? 0
            data += "\(number),\(scoreValue)\n"
        }
        return data
    }

    private func cleanupTemporaryFile() {
        guard let url = csvFileURL else { return }
        try? FileManager.default.removeItem(at: url)
        csvFileURL = nil
    }
}

#Preview {
    struct PreviewView: View {
        @StateObject var scoreModel = ScoreModel()

        var body: some View {
            ShareExportView(fileName: "TestJudge")
                .environmentObject(scoreModel)
        }
    }

    return PreviewView()
}

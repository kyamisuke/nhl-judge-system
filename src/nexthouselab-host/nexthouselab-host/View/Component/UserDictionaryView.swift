//
//  UserDictionaryView.swift
//  nexthouselab-host
//
//  Created by 村上航輔 on 2024/05/08.
//

import SwiftUI
import UniformTypeIdentifiers
 
struct FolderImportView: View {
    @State private var showsImportDocumentPicker = false
    @State private var fileName = ""
    @Binding var fileContent: String
    @Binding var entryNum: Int
    let buttonColor = Color(hue: 0.1, saturation: 0.8, brightness: 1)
    let lightColor = Color(hue: 0.1, saturation: 0.5, brightness: 1)
    let shadowColor = Color(hue: 0.1, saturation: 1, brightness: 0.8)
    let radius = CGFloat(12)
 
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(fileName)\nエントリー総数：\(entryNum)")
                    .onAppear {
                        guard let savedFileName = UserDefaults.standard.string(forKey: Const.FILE_NAME_KEY) else { return }
                        fileName = savedFileName
                    }
                    .font(.system(size: 12, weight: .regular, design: .default))
                Button("Import") {
                    showsImportDocumentPicker = true
                }
                .buttonStyle(.custom)
                .tint(Const.importColor)
//                CrayButtton(label: "Import", hue: 0.1, radius: radius) {
//                    showsImportDocumentPicker = true
//                }
            }
        }
        .sheet(isPresented: $showsImportDocumentPicker) {
            // 2. ユーザにファイルを選択させ、その内容を読み取る。
            DocumentPickerView(openingContentTypes: [UTType.text])
            .didPickDocument { fileURL in
                do {
                    guard fileURL.startAccessingSecurityScopedResource() else { return }
                    defer { fileURL.stopAccessingSecurityScopedResource() }
                    fileName = (fileURL.path() as NSString).lastPathComponent
                    var fileContent = try String(contentsOf: fileURL, encoding: .utf8)
                    let regex = try NSRegularExpression(pattern: "\r\n|\n|\r", options: [])
                    let range = NSRange(location: 0, length: fileContent.utf16.count)
                    fileContent = regex.stringByReplacingMatches(in: fileContent, options: [], range: range, withTemplate: "\n")
                    self.fileContent = fileContent
                    UserDefaults.standard.set(fileContent, forKey: Const.SELCTED_FILE_KEY)
                    UserDefaults.standard.set(fileName, forKey: Const.FILE_NAME_KEY)
                } catch {
                    print("Failed to import")
                }
            }
        }
    }
}

struct DemoFolderExportView: View {
    @State private var showsExportDocumentPicker = false
 
    var body: some View {
        VStack(spacing: 0) {
            Button("exportToFile") {
                showsExportDocumentPicker = true
            }
        }
        .sheet(isPresented: $showsExportDocumentPicker) {
            // 1. ユーザにフォルダーを選択させ、そこにファイルを作成する。
            DocumentPickerView(openingContentTypes: [UTType.folder])
                .didPickDocument { directoryURL in
                    guard directoryURL.startAccessingSecurityScopedResource() else { return }
                    defer { directoryURL.stopAccessingSecurityScopedResource() }
                    let newFileURL = directoryURL.appendingPathComponent("fileName.tsv")
                    do {
                        try "kyami,kenshu,amazon".write(to: newFileURL, atomically: true, encoding: .utf8)
                    } catch {
                        print("Failed to export")
                    }
                }
        }
    }
}

struct FolderExportView: View {
    @State private var showsExportDocumentPicker = false
    
    let buttonColor = Color.init(red: 0.38, green: 0.28, blue: 0.86)
    let lightColor = Color.init(red: 0.54, green: 0.41, blue: 0.95)
    let shadowColor = Color.init(red: 0.25, green: 0.17, blue: 0.75)
    let radius = CGFloat(12)
    
    @EnvironmentObject var scoreModel: ScoreModel
 
    var body: some View {
        VStack(spacing: 0) {
            Button("Export", action: {
                showsExportDocumentPicker = true
            })
            .buttonStyle(.custom)
            .tint(Const.exportColor)
//            CrayButtton(label: "Export", hue: 0.7, radius: radius) {
//                showsExportDocumentPicker = true
//            }
        }
        .sheet(isPresented: $showsExportDocumentPicker) {
            // 1. ユーザにフォルダーを選択させ、そこにファイルを作成する。
            DocumentPickerView(openingContentTypes: [UTType.folder])
                .didPickDocument { directoryURL in
                    guard directoryURL.startAccessingSecurityScopedResource() else { return }
                    defer { directoryURL.stopAccessingSecurityScopedResource() }
                    for (name, scores) in scoreModel.scores {
                        let newFileURL = directoryURL.appendingPathComponent("\(name).csv")
                        do {
                            var data = ""
                            for (number, score) in scores.sorted(by: { Int($0.0)! < Int($1.0)! }) {
                                data += "\(number),\(score)\n"
                            }
                            try data.write(to: newFileURL, atomically: true, encoding: .utf8)
                        } catch {
                            print("Failed to export")
                        }
                    }
                }
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var fileContent: String = ""
        @StateObject var scoreModel = ScoreModel()
        
        var body: some View {
            FolderImportView(fileContent: $fileContent, entryNum: .constant(0))
            DemoFolderExportView()
            FolderExportView()
                .environmentObject(scoreModel)
        }
    }
    
    return PreviewView()
}

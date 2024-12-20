//
//  UserDictionaryView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/07.
//

import SwiftUI
import UniformTypeIdentifiers
 
struct FolderImportView: View {
    @State private var showsImportDocumentPicker = false
    @State private var fileName = ""
    @Binding var fileContent: String
 
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(fileName)
                    .onAppear {
                        guard let savedFileName = UserDefaults.standard.string(forKey: Const.FILE_NAME_KEY) else { return }
                        fileName = savedFileName
                    }
                Button("Import", action: {
                    showsImportDocumentPicker = true
                })
                .buttonStyle(.custom)
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
            Button("exportToFile", action: {
                showsExportDocumentPicker = true
            })
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
    let fileName: String
    @EnvironmentObject var scoreModel: ScoreModel
 
    var body: some View {
        VStack(spacing: 0) {
            Button("Export", action: {
                showsExportDocumentPicker = true
            })
            .buttonStyle(.custom)
        }
        .sheet(isPresented: $showsExportDocumentPicker) {
            // 1. ユーザにフォルダーを選択させ、そこにファイルを作成する。
            DocumentPickerView(openingContentTypes: [UTType.folder])
                .didPickDocument { directoryURL in
                    guard directoryURL.startAccessingSecurityScopedResource() else { return }
                    defer { directoryURL.stopAccessingSecurityScopedResource() }
                    let newFileURL = directoryURL.appendingPathComponent(fileName)
                    do {
                        var data = ""
                        for (number, score) in scoreModel.scores.sorted(by: { Int($0.0)! < Int($1.0)! }) {
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

#Preview {
    struct PreviewView: View {
        @State var fileContent: String = ""
        
        var body: some View {
            FolderImportView(fileContent: $fileContent)
            DemoFolderExportView()
        }
    }
    
    return PreviewView()
}

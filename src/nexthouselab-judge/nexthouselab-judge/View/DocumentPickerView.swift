//
//  DocumentPickerView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/07.
//

import SwiftUI
import UniformTypeIdentifiers
 
struct DocumentPickerView : UIViewControllerRepresentable {
    let openingContentTypes: [UTType]
    let asCopy: Bool
 
    private var didPickDocumentCallback: ((URL) -> Void)?
 
    init(openingContentTypes: [UTType], asCopy: Bool = false) {
        self.openingContentTypes = openingContentTypes
        self.asCopy = asCopy
    }
 
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPickerViewController =  UIDocumentPickerViewController(forOpeningContentTypes: openingContentTypes, asCopy: asCopy)
        documentPickerViewController.delegate = context.coordinator
        return documentPickerViewController
    }
 
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
 
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
 
    /// ドキュメントが選択された際のコールバックを指定します
    func didPickDocument(callback: @escaping (URL) -> Void) -> Self {
        var view = self
        view.didPickDocumentCallback = callback
        return view
    }
 
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPickerView
 
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
 
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
            self.parent.didPickDocumentCallback?(url)
        }
    }
}

//
//  AlertTextFieldView.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 05/12/24.
//

import SwiftUI

typealias RenameCallback = (String, String) -> Void

struct AlertTextFieldView: View {
    let title: String
    @State private var text: String = ""
    let onRename: RenameCallback
    
    init(_ title: String, initialText: String, onRename: @escaping RenameCallback) {
        self._text = State(initialValue: initialText)
        self.title = title
        self.onRename = onRename
    }
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("Rename \(title)", text: $text)
            .focused($isFocused)
            .onSubmit { submit() }
        
        Button("Rename", action: submit)
        
        Button("Cancel", role: .cancel) {
            isFocused = false
        }
    }
    
    func submit() {
        isFocused = false
        if text.isEmpty { return }
        if title != text {
            onRename(title, text)
        }
    }
}

#Preview {
    let currentMedia: (any MediaProtocol)? = MovieMedia(displayName: "Movie 1", mediaFile: .moviesDirectory, creationDate: .distantPast)
    VStack {
        
    }
    .alert("Rename", isPresented: .constant(true), presenting: currentMedia) { media in
        AlertTextFieldView(media.displayName, initialText: media.displayName) {
            print($0, $1)
        }
    } message: { media in
        Text("Renaming \(media.displayName)")
    }
}

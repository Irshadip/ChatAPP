//
//  alertModifier.swift
//  ST_Chat
//
//  Created by Siddhesh on 15/02/24.
//

import SwiftUI

struct alertModifier: ViewModifier {
    @Binding var isPresented: Bool
    var title: String
    var message: String
    func body(content: Content) -> some View {
        content.alert(isPresented: $isPresented) {
            Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK")))
        }
    }
}

extension View {
    func alert(isPresented: Binding<Bool>, title: String, message: String) -> some View {
        self.modifier(alertModifier(isPresented: isPresented, title: title, message: message))
    }
}

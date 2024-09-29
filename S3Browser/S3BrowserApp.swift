//
//  S3BrowserApp.swift
//  S3Browser
//
//  Created by Emil Marashliev on 27.09.24.
//

import ComposableArchitecture
import SwiftUI

@main
struct S3BrowserApp: App {
    let store = Store(initialState: AppCoreDomain.State(authenticated: true)) {
        AppCoreDomain()
    }
    
    var body: some Scene {
        WindowGroup {
            AppCoreView(store: store)
//            ContentView()
        }
    }
}

//
//  BOATApp.swift
//  BOAT
//
//  Created by 이승용 on 6/8/26.
//

import SwiftUI
import FirebaseCore

@main
struct BOATApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

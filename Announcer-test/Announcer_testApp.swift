//
//  Announcer_testApp.swift
//  Announcer-test
//
//  Created by Lee Jun Lei Adam on 6/10/24.
//

import SwiftUI

@main
struct Announcer_testApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(after: .sidebar) {
                Button("Toggle Categories") {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                
                Button("Clear All Filters") {
                    // Add a way to pass the command to ContentView
                    NotificationCenter.default.post(name: .clearAllFilters, object: nil)
                }
                .keyboardShortcut("l", modifiers: .command)
            }
        }
    }
}

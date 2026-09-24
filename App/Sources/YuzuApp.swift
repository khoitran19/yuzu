import AppKit
import SwiftUI

@main
struct YuzuApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var services = AppServices()

    var body: some Scene {
        WindowGroup(id: "main") {
            RootView()
                .environment(services)
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1600, height: 1000)
        .commands {
            PullRequestCommands()
            CommandGroup(after: .appSettings) {
                if services.isSignedIn, services.options.fixture == nil {
                    Button("Sign Out") { services.signOut() }
                }
            }
        }

        Settings {
            SettingsView()
                .environment(services)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        switch LaunchOptions.current.appearance {
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        default: break
        }
        NSWindow.allowsAutomaticWindowTabbing = true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

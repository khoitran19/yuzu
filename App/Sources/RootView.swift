import AppKit
import SignIn
import SwiftUI

struct RootView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Group {
            if let service = services.service {
                MainWindowView(service: service)
            } else {
                SignInView(session: services.auth)
            }
        }
        .task {
            if services.options.settings { return await captureSettings() }
            guard services.options.fixture == nil else { return }
            await services.auth.bootstrap()
            await captureSignInIfRequested()
        }
    }

    /// Harness: with `--screenshot` and no session, captures the sign-in screen and quits.
    private func captureSignInIfRequested() async {
        guard let url = services.options.screenshot, services.service == nil else { return }
        try? await Task.sleep(for: .seconds(services.options.settleSeconds))
        if let window = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeMain }) {
            try? await WindowSnapshot.write(window, to: url)
        }
        NSApp.terminate(nil)
    }

    /// Harness: with `--settings --screenshot`, captures the Settings window and quits.
    private func captureSettings() async {
        openSettings()
        try? await Task.sleep(for: .seconds(services.options.settleSeconds))
        if let url = services.options.screenshot,
           let window = NSApp.windows.first(where: { $0.isVisible && $0.identifier?.rawValue.contains("Settings") == true }) {
            try? await WindowSnapshot.write(window, to: url)
        }
        NSApp.terminate(nil)
    }
}

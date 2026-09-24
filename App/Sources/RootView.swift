import AppKit
import SignIn
import SwiftUI

struct RootView: View {
    @Environment(AppServices.self) private var services

    var body: some View {
        Group {
            if services.service != nil {
                MainWindowView()
            } else {
                SignInView(session: services.auth)
            }
        }
        .task {
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
}

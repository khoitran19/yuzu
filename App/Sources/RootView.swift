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
            if services.options.fixture == nil { await services.auth.bootstrap() }
        }
    }
}

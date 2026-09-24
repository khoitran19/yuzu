import AppKit
import GitHubKit
import SwiftUI

public struct SignInView: View {
    private let session: AuthSession
    @State private var copiedCode: String?

    public init(session: AuthSession) {
        self.session = session
    }

    public var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .accessibilityHidden(true)
                Text("Yuzu")
                    .font(.title.bold())
                Text("Review large GitHub pull requests.")
                    .foregroundStyle(.secondary)
            }
            content
                .frame(maxWidth: .infinity)
        }
        .padding(32)
        .frame(width: 380)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.separator))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: session.state) { _, state in
            guard case let .awaitingCode(code) = state else { return }
            copy(code.userCode)
            NSWorkspace.shared.open(code.verificationURI)
        }
    }

    @ViewBuilder private var content: some View {
        switch session.state {
        case .loading:
            ProgressView()
                .controlSize(.small)
        case .signedOut:
            Button("Sign in with GitHub") { session.signIn() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("signIn.button")
        case let .awaitingCode(code):
            codeContent(code)
        case let .signedIn(_, viewer):
            Text("Signed in as \(viewer.login)")
                .foregroundStyle(.secondary)
        case let .failed(message):
            VStack(spacing: 12) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Retry") { session.retry() }
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("signIn.retry")
            }
        }
    }

    private func codeContent(_ code: DeviceCode) -> some View {
        VStack(spacing: 14) {
            Text("Enter this code on GitHub")
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Text(code.userCode)
                    .font(.system(size: 30, weight: .semibold, design: .monospaced))
                    .textSelection(.enabled)
                    .accessibilityIdentifier("signIn.code")
                Button {
                    copy(code.userCode)
                } label: {
                    Label(copiedCode == code.userCode ? "Copied" : "Copy",
                          systemImage: copiedCode == code.userCode ? "checkmark" : "doc.on.doc")
                }
            }
            HStack(spacing: 4) {
                Text("The code is on your clipboard.")
                Button("Open GitHub") { NSWorkspace.shared.open(code.verificationURI) }
                    .buttonStyle(.link)
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Waiting for GitHub…")
                    .foregroundStyle(.secondary)
            }
            Button("Cancel") { session.cancel() }
                .keyboardShortcut(.cancelAction)
        }
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copiedCode = text
    }
}

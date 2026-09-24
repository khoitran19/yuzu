import AppKit
import AppShortcuts
import PRModels
import SwiftUI

struct HomeView: View {
    @Environment(AppServices.self) private var services
    @Binding var address: String
    let open: (String) -> Void
    @State private var clipboardRef: PRRef?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .accessibilityHidden(true)
                    Text("Open a pull request")
                        .font(.largeTitle.weight(.semibold))
                    Text("Paste a GitHub link, such as github.com/owner/repo/pull/123, or owner/repo#123.")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    TextField("https://github.com/owner/repo/pull/123", text: $address)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.title3, design: .monospaced))
                        .onSubmit { open(address) }
                        .accessibilityIdentifier("home.address")
                    Button("Open") { open(address) }
                        .keyboardShortcut(.defaultAction)
                        .controlSize(.large)
                        .disabled(PRRef(string: address) == nil)
                }
                if let clipboardRef {
                    Button {
                        open(clipboardRef.webURL.absoluteString)
                    } label: {
                        Label("Open \(clipboardRef.displayName) from the clipboard", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.link)
                    .help(Shortcut.openFromClipboard.symbols)
                    .accessibilityIdentifier("home.clipboard")
                }
                if !services.recents.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent").font(.headline).padding(.bottom, 4)
                        ForEach(services.recents.entries) { entry in
                            RecentRow(entry: entry) { open(entry.ref.webURL.absoluteString) }
                                .contextMenu {
                                    Button("Remove from Recent") { services.recents.remove(entry.ref) }
                                }
                        }
                    }
                }
            }
            .padding(40)
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .onAppear(perform: readClipboard)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in readClipboard() }
    }

    private func readClipboard() {
        clipboardRef = NSPasteboard.general.string(forType: .string).flatMap(PRRef.init(string:))
        if let clipboardRef { services.prefetch(clipboardRef) }
    }
}

private struct RecentRow: View {
    let entry: RecentPullRequests.Entry
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.pull").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title).lineLimit(1)
                    Text(entry.ref.displayName).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                Spacer()
                Text(entry.openedAt, format: .relative(presentation: .named)).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(hovering ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear), in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

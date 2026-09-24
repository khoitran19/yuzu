import ReviewRules
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            ReviewRulesSettings()
                .tabItem { Label("Review Rules", systemImage: "line.3.horizontal.decrease.circle") }
        }
        .frame(width: 620, height: 560)
    }
}

private struct ReviewRulesSettings: View {
    @Environment(AppServices.self) private var services
    @State private var collapsed = ""
    @State private var autoViewed = ""
    @State private var testPath = "apps/web/src/__tests__/checkout.spec.ts"

    var body: some View {
        Form {
            Section {
                PatternEditor(text: $collapsed, identifier: "settings.collapsed")
            } header: {
                Text("Collapse in file tree")
            } footer: {
                Text("Folders that match start collapsed in the file tree.")
            }
            Section {
                PatternEditor(text: $autoViewed, identifier: "settings.autoViewed")
            } header: {
                Text("Mark as viewed")
            } footer: {
                Text("Files that match are marked Viewed on GitHub when a pull request opens. Viewed files collapse in the diff.")
            }
            Section("Pattern syntax") {
                Text("One glob per line, as in .gitignore. `__tests__` or `*.spec.ts` matches at any depth. `docs/**` matches from the root. `**` crosses folders; `*` does not. Lines that start with # are comments.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section("Test a path") {
                TextField("Path", text: $testPath)
                    .font(.system(.body, design: .monospaced))
                let matcher = ReviewRules(collapsedInTree: lines(collapsed), autoViewed: lines(autoViewed)).matcher
                let folder = testPath.split(separator: "/").dropLast().joined(separator: "/")
                LabeledContent("Folder collapsed in tree", value: !folder.isEmpty && matcher.isCollapsedInTree(directory: folder) ? "Yes" : "No")
                LabeledContent("File marked as viewed", value: matcher.isAutoViewed(file: testPath) ? "Yes" : "No")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            collapsed = services.rulesStore.rules.collapsedInTree.joined(separator: "\n")
            autoViewed = services.rulesStore.rules.autoViewed.joined(separator: "\n")
        }
        .onChange(of: collapsed) { _, value in services.rulesStore.rules.collapsedInTree = lines(value) }
        .onChange(of: autoViewed) { _, value in services.rulesStore.rules.autoViewed = lines(value) }
    }

    private func lines(_ text: String) -> [String] {
        text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

private struct PatternEditor: View {
    @Binding var text: String
    let identifier: String

    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .frame(minHeight: 90)
            .scrollContentBackground(.hidden)
            .accessibilityIdentifier(identifier)
    }
}

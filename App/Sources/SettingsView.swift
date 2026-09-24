import AppShortcuts
import ReviewRules
import SwiftUI

struct SettingsView: View {
    enum Tab: String { case rules, shortcuts }

    @State private var tab = LaunchOptions.current.settingsTab ?? .rules

    var body: some View {
        TabView(selection: $tab) {
            ReviewRulesSettings()
                .tabItem { Label("Review Rules", systemImage: "checkmark.rectangle.stack") }
                .tag(Tab.rules)
            ShortcutsSettings()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
                .tag(Tab.shortcuts)
        }
        .frame(width: 560, height: 620)
    }
}

private struct ShortcutsSettings: View {
    var body: some View {
        Form {
            ForEach(Shortcut.Area.allCases) { area in
                Section(area.rawValue) {
                    ForEach(Shortcut.all.filter { $0.area == area }) { shortcut in
                        LabeledContent(shortcut.title) { KeyCaps(shortcut: shortcut) }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .accessibilityIdentifier("settings.shortcuts")
    }
}

private struct KeyCaps: View {
    let shortcut: Shortcut

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(shortcut.keyCaps.enumerated()), id: \.offset) { index, caps in
                if index > 0 { Text("or").font(.caption).foregroundStyle(.secondary) }
                HStack(spacing: 3) {
                    ForEach(Array(caps.enumerated()), id: \.offset) { _, cap in
                        Text(cap)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .frame(minWidth: 14)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 5).fill(.quaternary))
                            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(.separator))
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shortcut.keyCaps.map { $0.joined() }.joined(separator: " or "))
    }
}

private struct ReviewRulesSettings: View {
    @Environment(AppServices.self) private var services
    @State private var patterns = ""
    @State private var testPath = "apps/web/src/__tests__/checkout.spec.ts"

    var body: some View {
        Form {
            Section {
                TextEditor(text: $patterns)
                    .font(.system(.callout, design: .monospaced))
                    .frame(height: 320)
                    .scrollContentBackground(.hidden)
                    .accessibilityIdentifier("settings.autoViewed")
                HStack {
                    Text("One glob per line, as in .gitignore. Lines that start with # are comments.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Restore Defaults") { patterns = Self.text(ReviewRules.defaults) }
                        .disabled(Self.lines(patterns) == ReviewRules.defaults.autoViewed)
                }
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mark as viewed")
                    Text(
                        "Matching files are marked Viewed on GitHub when a pull request opens. They collapse in the diff and dim in the file tree."
                    )
                    .font(.callout)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
                }
            }
            Section("Test a path") {
                TextField("Path", text: $testPath)
                    .labelsHidden()
                    .font(.system(.body, design: .monospaced))
                    .accessibilityIdentifier("settings.testPath")
                MatchResult(pattern: ReviewRules(autoViewed: Self.lines(patterns)).matcher.autoViewedPattern(file: testPath))
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Review Rules")
        .onAppear { patterns = Self.text(services.rulesStore.rules) }
        .onChange(of: patterns) { _, value in services.rulesStore.rules.autoViewed = Self.lines(value) }
    }

    private static func text(_ rules: ReviewRules) -> String {
        rules.autoViewed.joined(separator: "\n")
    }

    private static func lines(_ text: String) -> [String] {
        text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

private struct MatchResult: View {
    let pattern: String?

    var body: some View {
        if let pattern {
            Label {
                Text("Marked as viewed by ") + Text(pattern).font(.system(.body, design: .monospaced))
            } icon: {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        } else {
            Label {
                Text("No match. The file stays unviewed.").foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "circle").foregroundStyle(.secondary)
            }
        }
    }
}

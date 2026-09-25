import Foundation
import PRDetail
import PRFixtures
import PRModels
import ReviewRules

/// Command-line options for the QA harness. Normal launches pass none.
struct LaunchOptions {
    var fixture: URL?
    var open: PRRef?
    var screenshot: URL?
    var perfOutput: URL?
    var perfPixelsPerSecond: Double = 6_000
    var appearance: String?
    var windowSize: CGSize?
    var tab: PRDetailModel.Tab?
    var pullRequestList: PullRequestListScope?
    var emptyPullRequestLists = false
    var scrollToFile: String?
    var preview: String?
    var previewScript: String?
    /// A JavaScript `scrollTo` y value for the Summary page, or `bottom`.
    var summaryScroll: String?
    /// A CSS selector for a Summary page element to click, such as a link.
    var summaryClick: String?
    /// Replaces the fixture's merge box state.
    var mergeStatus: MergeStatusPreset?
    /// Pull requests to open in new tabs after the first one loads.
    var openTabs: [PRRef] = []
    /// Texts to submit in the address field after the first pull request loads, such as `@rik`.
    var submits: [String] = []
    /// Key combinations, such as `shift+cmd+]`, that the main menu gets after the tabs open.
    var keys: [String] = []
    var collapseAll = false
    var settings = false
    var settingsTab: SettingsView.Tab?
    var toggleViewed: [String] = []
    var expand: [(path: String, hunk: Int?)] = []
    var rules: ReviewRules?
    var settleSeconds: Double = 1.0
    var latency: Duration = .zero

    var isHarness: Bool { screenshot != nil || perfOutput != nil }

    static let current = LaunchOptions(arguments: CommandLine.arguments)

    init(arguments: [String]) {
        var iterator = arguments.dropFirst().makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--fixture": fixture = iterator.next().map { URL(filePath: $0) }
            case "--open": open = iterator.next().flatMap(PRRef.init(string:))
            case "--screenshot": screenshot = iterator.next().map { URL(filePath: $0) }
            case "--perf-scroll": perfOutput = iterator.next().map { URL(filePath: $0) }
            case "--perf-speed": perfPixelsPerSecond = iterator.next().flatMap(Double.init) ?? perfPixelsPerSecond
            case "--appearance": appearance = iterator.next()
            case "--window-size":
                let parts = iterator.next()?.split(separator: "x").compactMap { Double($0) } ?? []
                if parts.count == 2 { windowSize = CGSize(width: parts[0], height: parts[1]) }
            case "--tab": tab = iterator.next().flatMap { $0 == "summary" ? .summary : $0 == "files" ? .files : nil }
            case "--pr-list": pullRequestList = iterator.next().flatMap(PullRequestListScope.init(rawValue:))
            case "--pr-list-empty": emptyPullRequestLists = true
            case "--scroll-to-file": scrollToFile = iterator.next()
            case "--preview": preview = iterator.next()
            case "--preview-script": previewScript = iterator.next()
            case "--summary-scroll": summaryScroll = iterator.next()
            case "--summary-click": summaryClick = iterator.next()
            case "--merge-status": mergeStatus = iterator.next().flatMap(MergeStatusPreset.init(rawValue:))
            case "--open-tab": if let ref = iterator.next().flatMap(PRRef.init(string:)) { openTabs.append(ref) }
            case "--key": if let key = iterator.next() { keys.append(key) }
            case "--submit": if let text = iterator.next() { submits.append(text) }
            case "--collapse-all": collapseAll = true
            case "--settings": settings = true
            case "--settings-tab":
                settings = true
                settingsTab = iterator.next().flatMap(SettingsView.Tab.init(rawValue:))
            case "--toggle-viewed": if let path = iterator.next() { toggleViewed.append(path) }
            case "--expand":
                if let value = iterator.next(), let colon = value.lastIndex(of: ":") {
                    expand.append((String(value[..<colon]), Int(value[value.index(after: colon)...])))
                }
            case "--rules": rules = iterator.next().flatMap { try? JSONDecoder().decode(ReviewRules.self, from: Data($0.utf8)) }
            case "--settle": settleSeconds = iterator.next().flatMap(Double.init) ?? settleSeconds
            case "--latency": latency = .milliseconds(iterator.next().flatMap(Int.init) ?? 0)
            default: continue
            }
        }
    }
}

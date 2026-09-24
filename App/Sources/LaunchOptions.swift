import Foundation
import PRDetail
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
    var scrollToFile: String?
    var collapseAll = false
    var toggleViewed: [String] = []
    var rules: ReviewRules?
    var settleSeconds: Double = 1.0

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
            case "--scroll-to-file": scrollToFile = iterator.next()
            case "--collapse-all": collapseAll = true
            case "--toggle-viewed": if let path = iterator.next() { toggleViewed.append(path) }
            case "--rules": rules = iterator.next().flatMap { try? JSONDecoder().decode(ReviewRules.self, from: Data($0.utf8)) }
            case "--settle": settleSeconds = iterator.next().flatMap(Double.init) ?? settleSeconds
            default: continue
            }
        }
    }
}

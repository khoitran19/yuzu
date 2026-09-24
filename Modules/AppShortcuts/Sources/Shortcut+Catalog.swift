extension Shortcut {
    public static let openPullRequest = Shortcut(
        "openPullRequest", "Open Pull Request…", area: .general, keys: [.character("l")], modifiers: .command)
    public static let openFromClipboard = Shortcut(
        "openFromClipboard", "Open Pull Request from Clipboard", area: .general, keys: [.character("v")], modifiers: [.shift, .command]
    )
    public static let myPullRequests = Shortcut(
        "myPullRequests", "My Pull Requests", area: .general, keys: [.character("d")], modifiers: .command)
    public static let otherPullRequests = Shortcut(
        "otherPullRequests", "Other Pull Requests", area: .general, keys: [.character("d")], modifiers: [.shift, .command]
    )
    public static let showSummary = Shortcut("showSummary", "Show Summary", area: .general, keys: [.character("1")], modifiers: .control)
    public static let showFiles = Shortcut("showFiles", "Show Files Changed", area: .general, keys: [.character("2")], modifiers: .control)

    public static let summaryTab = Shortcut("summaryTab", "Summary tab", area: .pullRequest, keys: [.character("1")], modifiers: .command)
    public static let filesTab = Shortcut("filesTab", "Files changed tab", area: .pullRequest, keys: [.character("2")], modifiers: .command)
    public static let collapseAll = Shortcut(
        "collapseAll", "Collapse All Files", area: .pullRequest, keys: [.character("[")], modifiers: [.option, .command]
    )
    public static let expandAll = Shortcut(
        "expandAll", "Expand All Files", area: .pullRequest, keys: [.character("]")], modifiers: [.option, .command])
    public static let toggleFileTree = Shortcut(
        "toggleFileTree", "Show or Hide File Tree", area: .pullRequest, keys: [.character("b")], modifiers: [.shift, .command]
    )
    public static let toggleMarkdownPreview = Shortcut(
        "toggleMarkdownPreview", "Show or Hide Markdown Preview", area: .pullRequest, keys: [.character("m")],
        modifiers: [.shift, .command])

    public static let nextFile = Shortcut("nextFile", "Next file", area: .diff, keys: [.character("j"), .character("n")])
    public static let previousFile = Shortcut("previousFile", "Previous file", area: .diff, keys: [.character("k"), .character("p")])
    public static let toggleViewed = Shortcut("toggleViewed", "Mark the file as viewed or not viewed", area: .diff, keys: [.character("v")])
    public static let previewFile = Shortcut("previewFile", "Preview the Markdown file", area: .diff, keys: [.character("m")])
    public static let toggleCollapse = Shortcut(
        "toggleCollapse", "Collapse or expand the file", area: .diff, keys: [.character("x"), .character("o")]
    )
    public static let copyLines = Shortcut(
        "copyLines", "Copy the selected lines", area: .diff, keys: [.character("c")], modifiers: .command)
    public static let clearSelection = Shortcut("clearSelection", "Clear the line selection", area: .diff, keys: [.escape])

    public static let openTreeItem = Shortcut(
        "openTreeItem", "Show the file, or open or close the folder", area: .fileTree, keys: [.returnKey])

    public static let filterToTree = Shortcut("filterToTree", "Move to the first file", area: .fileFilter, keys: [.downArrow])
    public static let filterOpenFirst = Shortcut("filterOpenFirst", "Show the first file", area: .fileFilter, keys: [.returnKey])

    public static let panelPrevious = Shortcut("panelPrevious", "Previous pull request", area: .panel, keys: [.upArrow])
    public static let panelNext = Shortcut("panelNext", "Next pull request", area: .panel, keys: [.downArrow])
    public static let panelOpen = Shortcut("panelOpen", "Open the selected pull request", area: .panel, keys: [.returnKey])
    public static let panelClose = Shortcut("panelClose", "Close the panel", area: .panel, keys: [.escape])

    /// Every shortcut, in settings order.
    public static let all: [Shortcut] = [
        openPullRequest, openFromClipboard, myPullRequests, otherPullRequests, showSummary, showFiles,
        summaryTab, filesTab, collapseAll, expandAll, toggleFileTree, toggleMarkdownPreview,
        nextFile, previousFile, toggleViewed, previewFile, toggleCollapse, copyLines, clearSelection,
        openTreeItem,
        filterToTree, filterOpenFirst,
        panelPrevious, panelNext, panelOpen, panelClose,
    ]
}

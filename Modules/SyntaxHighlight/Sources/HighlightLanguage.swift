import Foundation
import TreeSitterBash
import TreeSitterCSS
import TreeSitterGo
import TreeSitterJavaScript
import TreeSitterJSON
import TreeSitterMarkdown
import TreeSitterPython
import TreeSitterRust
import TreeSitterSql
import TreeSitterSwift
import TreeSitterTSX
import TreeSitterTypeScript
import TreeSitterYAML

enum HighlightLanguage: CaseIterable, Sendable {
    case typescript, tsx, javascript, json, sql, swift, yaml, css, python, go, rust, bash, markdown

    init?(path: String) {
        switch (path as NSString).pathExtension.lowercased() {
        case "ts", "mts", "cts": self = .typescript
        case "tsx": self = .tsx
        case "js", "mjs", "cjs", "jsx": self = .javascript
        case "json": self = .json
        case "sql": self = .sql
        case "swift": self = .swift
        case "yml", "yaml": self = .yaml
        case "css": self = .css
        case "py", "pyi": self = .python
        case "go": self = .go
        case "rs": self = .rust
        case "sh", "bash": self = .bash
        case "md", "markdown": self = .markdown
        default: return nil
        }
    }

    var configuration: HighlightConfiguration? {
        switch self {
        case .typescript: Configurations.typescript
        case .tsx: Configurations.tsx
        case .javascript: Configurations.javascript
        case .json: Configurations.json
        case .sql: Configurations.sql
        case .swift: Configurations.swift
        case .yaml: Configurations.yaml
        case .css: Configurations.css
        case .python: Configurations.python
        case .go: Configurations.go
        case .rust: Configurations.rust
        case .bash: Configurations.bash
        case .markdown: Configurations.markdown
        }
    }

    var grammar: OpaquePointer {
        switch self {
        case .typescript: tree_sitter_typescript()
        case .tsx: tree_sitter_tsx()
        case .javascript: tree_sitter_javascript()
        case .json: tree_sitter_json()
        case .sql: tree_sitter_sql()
        case .swift: tree_sitter_swift()
        case .yaml: tree_sitter_yaml()
        case .css: tree_sitter_css()
        case .python: tree_sitter_python()
        case .go: tree_sitter_go()
        case .rust: tree_sitter_rust()
        case .bash: tree_sitter_bash()
        case .markdown: tree_sitter_markdown()
        }
    }

    /// Query files in `Resources/Queries`. For one node, the capture from the last matching pattern wins.
    var queryNames: [String] {
        switch self {
        case .typescript: ["typescript", "javascript"]
        case .tsx: ["typescript", "javascript", "jsx"]
        case .javascript: ["javascript", "jsx"]
        case .json: ["json"]
        case .sql: ["sql"]
        case .swift: ["swift"]
        case .yaml: ["yaml"]
        case .css: ["css"]
        case .python: ["python"]
        case .go: ["go"]
        case .rust: ["rust"]
        case .bash: ["bash"]
        case .markdown: ["markdown"]
        }
    }
}

private enum Configurations {
    static let typescript = try? HighlightConfiguration(.typescript)
    static let tsx = try? HighlightConfiguration(.tsx)
    static let javascript = try? HighlightConfiguration(.javascript)
    static let json = try? HighlightConfiguration(.json)
    static let sql = try? HighlightConfiguration(.sql)
    static let swift = try? HighlightConfiguration(.swift)
    static let yaml = try? HighlightConfiguration(.yaml)
    static let css = try? HighlightConfiguration(.css)
    static let python = try? HighlightConfiguration(.python)
    static let go = try? HighlightConfiguration(.go)
    static let rust = try? HighlightConfiguration(.rust)
    static let bash = try? HighlightConfiguration(.bash)
    static let markdown = try? HighlightConfiguration(.markdown)
}

/// Preview layout, change markers, and diff token colors. Adds to `SummaryStyle.css`.
nonisolated enum MarkdownStyle {
    static let css = """
    body { padding: 20px 28px 64px 40px; position: relative; }
    .markdown-body { max-width: 880px; font-size: 15px; }
    .markdown-body .tight > li > p { margin: 0; }
    .markdown-body li > ul, .markdown-body li > ol { margin: .25em 0 0; }
    .markdown-body h1, .markdown-body h2, .markdown-body h3, .markdown-body h4, .markdown-body h5, .markdown-body h6 { position: relative; }
    .markdown-body .anchor { position: absolute; left: -20px; padding-right: 4px; color: var(--muted); opacity: 0; font-weight: 400; }
    .markdown-body :hover > .anchor { opacity: 1; text-decoration: none; }
    .markdown-body table.front-matter td { white-space: pre-wrap; }
    .markdown-body [data-start] { transition: background-color .15s, box-shadow .15s; }
    .markdown-body .prv-hover { background-color: var(--add); box-shadow: 0 0 0 4px var(--add); border-radius: 2px; }
    .markdown-body .prv-flash { animation: prv-flash 1.2s ease-out; }
    @keyframes prv-flash { from { background-color: var(--add-num); box-shadow: 0 0 0 6px var(--add-num); } }
    .end-marker { height: 1px; }
    .html-marker { height: 0; }

    #prv-gutter { position: absolute; left: 0; top: 0; width: 32px; }
    #prv-gutter .bar { position: absolute; left: 16px; width: 4px; border-radius: 2px; cursor: pointer; }
    #prv-gutter .bar::before { content: ""; position: absolute; inset: 0 -6px; }
    #prv-gutter .bar.add { background: var(--success); }
    #prv-gutter .bar.add:hover { left: 15px; width: 6px; }
    #prv-gutter .bar.del { left: 13px; width: 10px; height: 4px; background: var(--danger); }

    .tk-keyword, .tk-operator { color: #cf222e; } .tk-string { color: #0a3069; }
    .tk-number, .tk-constant, .tk-property, .tk-attribute { color: #0550ae; } .tk-comment { color: #59636e; }
    .tk-function { color: #8250df; } .tk-type, .tk-variable { color: #953800; } .tk-tag { color: #116329; }
    @media (prefers-color-scheme: dark) {
      .tk-keyword, .tk-operator { color: #ff7b72; } .tk-string { color: #a5d6ff; }
      .tk-number, .tk-constant, .tk-property, .tk-attribute { color: #79c0ff; } .tk-comment { color: #9198a1; }
      .tk-function { color: #d2a8ff; } .tk-type, .tk-variable { color: #ffa657; } .tk-tag { color: #7ee787; }
    }
    """
}

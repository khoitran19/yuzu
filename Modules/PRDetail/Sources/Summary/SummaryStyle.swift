/// GitHub Primer colors and the Conversation page layout.
nonisolated enum SummaryStyle {
    static let css = """
    :root { color-scheme: light dark;
      --canvas: #ffffff; --fg: #1f2328; --muted: #59636e; --border: #d1d9e0; --border-muted: #d1d9e0b3; --subtle: #f6f8fa;
      --accent: #0969da; --success: #1a7f37; --success-em: #1f883d; --danger: #d1242f; --danger-em: #cf222e;
      --attention: #9a6700; --attention-em: #bf8700; --code: #818b981f; --add: #dafbe1; --add-num: #aceebb;
      --del: #ffebe9; --del-num: #ffcecb; --neutral: #afb8c133; --header: #f6f8fa; }
    @media (prefers-color-scheme: dark) { :root {
      --canvas: #0d1117; --fg: #f0f6fc; --muted: #9198a1; --border: #3d444d; --border-muted: #3d444db3; --subtle: #151b23;
      --accent: #4493f8; --success: #3fb950; --success-em: #238636; --danger: #f85149; --danger-em: #da3633;
      --attention: #d29922; --attention-em: #9e6a03; --code: #656c7633; --add: #2ea04326; --add-num: #3fb9504d;
      --del: #f8514926; --del-num: #f851494d; --neutral: #656c7633; --header: #151b23; } }
    html { background: var(--canvas); }
    body { font: 14px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif;
      color: var(--fg); margin: 0; padding: 24px 16px 48px; }
    a { color: var(--accent); text-decoration: none; } a:hover { text-decoration: underline; }
    .muted, a.muted { color: var(--muted); }
    .grow { flex: 1; }
    .discussion { position: relative; max-width: 900px; margin: 0 auto; padding-left: 56px; }
    .discussion::before { content: ""; position: absolute; top: 0; bottom: 0; left: 72px; width: 2px; background: var(--border-muted); }

    .avatar { border-radius: 50%; background: var(--subtle); flex-shrink: 0; vertical-align: middle; box-shadow: 0 0 0 1px var(--border-muted); }
    .avatar.placeholder { display: inline-grid; place-items: center; color: var(--muted); font-weight: 600; }
    .avatar.inline { margin-right: 4px; }
    .tl-avatar { position: absolute; left: 0; top: 0; }
    .author { color: var(--fg); font-weight: 600; }
    .label { display: inline-block; margin-left: 4px; padding: 0 7px; font-size: 12px; font-weight: 500; line-height: 18px;
      border: 1px solid var(--border); border-radius: 2em; color: var(--muted); white-space: nowrap; }
    .label.bot { margin-left: 2px; }
    .label.attention { color: var(--attention); border-color: var(--attention-em); }

    .box { position: relative; background: var(--canvas); border: 1px solid var(--border); border-radius: 6px; }
    .box.arrow::before, .box.arrow::after { content: ""; position: absolute; top: 11px; right: 100%; left: -8px; display: block;
      width: 8px; height: 16px; pointer-events: none; clip-path: polygon(0 50%, 100% 0, 100% 100%); }
    .box.arrow::before { background: var(--border); }
    .box.arrow::after { margin-left: 1px; background: var(--header); }
    .box-header { display: flex; align-items: center; flex-wrap: wrap; gap: 4px; padding: 8px 16px; background: var(--header);
      border-bottom: 1px solid var(--border); border-radius: 6px 6px 0 0; color: var(--fg); min-height: 22px; }
    .box-header.sub { border-radius: 0; border-top: 1px solid var(--border); }
    .box > .markdown-body { padding: 16px; }
    /* content-visibility clips to the element, so the avatar column and arrow sit inside its padding. */
    .tl-comment { position: relative; margin: 0 0 16px -56px; padding-left: 56px; content-visibility: auto; contain-intrinsic-size: auto 160px; }

    details > summary { list-style: none; cursor: pointer; }
    details > summary::-webkit-details-marker { display: none; }
    details .link { color: var(--accent); font-size: 12px; }
    details:not([open]) .link.hide, details[open] .link.show { display: none; }
    details.minimized:not([open]) > .box-header { border-bottom: 0; border-radius: 6px; }

    .tl-event { position: relative; display: flex; padding: 16px 0; margin-left: 1px; content-visibility: auto; contain-intrinsic-size: auto 64px; }
    .tl-badge { position: relative; z-index: 1; display: grid; place-items: center; width: 32px; height: 32px; margin-right: 8px;
      flex-shrink: 0; border-radius: 50%; border: 2px solid var(--canvas); background: var(--subtle); color: var(--muted); box-sizing: border-box; }
    .tl-badge .octicon { fill: currentColor; }
    .tl-badge.approved { background: var(--success-em); color: #fff; }
    .tl-badge.changes { background: var(--danger-em); color: #fff; }
    .tl-event-body { flex: 1; min-width: 0; }
    .tl-event-line { display: flex; align-items: center; flex-wrap: wrap; gap: 4px; min-height: 32px; color: var(--muted); }
    .box.nested { margin-top: 12px; }
    .tl-end { position: relative; z-index: 1; height: 0; border-top: 2px solid var(--border); }

    .thread-header { display: flex; align-items: center; gap: 8px; padding: 8px 16px; background: var(--header);
      border-radius: 6px; font: 12px ui-monospace, SFMono-Regular, Menlo, monospace; }
    .thread[open] > .thread-header { border-bottom: 1px solid var(--border); border-radius: 6px 6px 0 0; }
    .thread-header .chevron { fill: var(--muted); transition: transform .1s; }
    .thread:not([open]) .chevron { transform: rotate(-90deg); }
    .thread-header .path { font-weight: 600; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .resolved { display: inline-flex; align-items: center; gap: 4px; font: 12px -apple-system, sans-serif; }
    .resolved .octicon { fill: var(--muted); }
    .hunk { width: 100%; border-collapse: collapse; font: 12px/20px ui-monospace, SFMono-Regular, Menlo, monospace; table-layout: fixed; }
    .hunk td { padding: 0 8px; white-space: pre; overflow: hidden; text-overflow: ellipsis; }
    .hunk td.num { width: 40px; text-align: right; color: var(--muted); user-select: none; }
    .hunk td.code { width: auto; }
    .hunk .marker { user-select: none; margin-right: 4px; }
    .hunk tr.add td { background: var(--add); } .hunk tr.add td.num { background: var(--add-num); }
    .hunk tr.del td { background: var(--del); } .hunk tr.del td.num { background: var(--del-num); }
    .thread-comments { border-top: 1px solid var(--border); }
    .thread-comment { display: flex; gap: 4px; padding: 12px 16px; }
    .thread-comment + .thread-comment { border-top: 1px solid var(--border-muted); }
    .tc-main { flex: 1; min-width: 0; }
    .tc-header { display: flex; align-items: center; gap: 4px; flex-wrap: wrap; min-height: 24px; }
    .tc-main .markdown-body { margin-top: 4px; }

    .merge-box { position: relative; z-index: 1; padding-top: 16px; background: var(--canvas); }
    .checks .checks-header { display: flex; align-items: center; gap: 12px; padding: 16px; border-radius: 6px; }
    .checks[open] .checks-header { border-bottom: 1px solid var(--border); border-radius: 6px 6px 0 0; }
    .checks-title { font-size: 16px; font-weight: 600; }
    .status-circle { display: grid; place-items: center; width: 32px; height: 32px; border-radius: 50%; flex-shrink: 0; color: #fff; }
    .status-circle .octicon { fill: currentColor; }
    .status-circle.success { background: var(--success-em); } .status-circle.failure { background: var(--danger-em); }
    .status-circle.pending { background: var(--attention-em); }
    .check-list { max-height: 480px; overflow: auto; }
    .check-row { display: flex; align-items: center; gap: 8px; padding: 8px 16px; font-size: 12px; }
    .check-row + .check-row { border-top: 1px solid var(--border-muted); }
    .check-row .state { display: inline-flex; } .check-row .octicon { fill: currentColor; }
    .state.success { color: var(--success); } .state.failure { color: var(--danger); } .state.pending { color: var(--attention); }
    .state.muted { color: var(--muted); }
    .app-avatar { width: 20px; height: 20px; border-radius: 4px; flex-shrink: 0; background: var(--subtle); }
    .check-text { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .check-row .label { margin-left: 0; }
    .details { font-weight: 500; }
    .loading { padding: 16px 0 16px 48px; }

    .markdown-body { overflow-wrap: break-word; line-height: 1.5; }
    .markdown-body > :first-child { margin-top: 0 !important; }
    .markdown-body > :last-child { margin-bottom: 0 !important; }
    .empty { color: var(--muted); font-style: italic; }
    .markdown-body h1, .markdown-body h2 { border-bottom: 1px solid var(--border-muted); padding-bottom: .3em; }
    .markdown-body h1 { font-size: 2em; } .markdown-body h2 { font-size: 1.5em; } .markdown-body h3 { font-size: 1.25em; }
    .markdown-body h4 { font-size: 1em; } .markdown-body h5 { font-size: .875em; } .markdown-body h6 { font-size: .85em; color: var(--muted); }
    .markdown-body h1, .markdown-body h2, .markdown-body h3, .markdown-body h4, .markdown-body h5, .markdown-body h6 {
      margin: 24px 0 16px; font-weight: 600; line-height: 1.25; }
    .markdown-body p, .markdown-body ul, .markdown-body ol, .markdown-body table, .markdown-body pre, .markdown-body blockquote,
    .markdown-body details, .markdown-body .highlight, .markdown-body .markdown-alert { margin: 0 0 16px; }
    .markdown-body ul, .markdown-body ol { padding-left: 2em; }
    .markdown-body li + li { margin-top: .25em; }
    .markdown-body code, .markdown-body pre, .markdown-body kbd { font: 85%/1.45 ui-monospace, SFMono-Regular, Menlo, monospace; }
    .markdown-body code { background: var(--code); padding: .2em .4em; border-radius: 6px; white-space: break-spaces; }
    .markdown-body pre { background: var(--subtle); padding: 16px; border-radius: 6px; overflow: auto; }
    .markdown-body pre code { background: none; padding: 0; font-size: 100%; white-space: pre; }
    .markdown-body .highlight pre { margin-bottom: 0; }
    .markdown-body kbd { padding: 3px 5px; font-size: 11px; border: 1px solid var(--border); border-bottom-width: 2px; border-radius: 6px; background: var(--subtle); }
    .markdown-body blockquote { color: var(--muted); border-left: .25em solid var(--border); padding: 0 1em; margin-left: 0; }
    .markdown-body table { border-collapse: collapse; display: block; width: max-content; max-width: 100%; overflow: auto; }
    .markdown-body th, .markdown-body td { border: 1px solid var(--border); padding: 6px 13px; }
    .markdown-body th { font-weight: 600; }
    .markdown-body tr:nth-child(2n) { background: var(--subtle); }
    .markdown-body img { max-width: 100%; box-sizing: content-box; }
    .markdown-body hr { border: 0; height: .25em; background: var(--border); margin: 24px 0; }
    .markdown-body input[type=checkbox] { margin: 0 .2em .25em -1.4em; vertical-align: middle; }
    .markdown-body .task-list-item { list-style: none; }
    .markdown-body .contains-task-list { padding-left: 2em; }
    .markdown-body summary { cursor: pointer; }
    .markdown-body details > summary { list-style: revert; }
    .markdown-body details > summary::-webkit-details-marker { display: revert; }
    .markdown-body .user-mention, .markdown-body .team-mention { font-weight: 600; color: var(--fg); }
    .markdown-body g-emoji { font-family: "Apple Color Emoji", "Segoe UI Emoji", sans-serif; font-size: 1.2em; vertical-align: middle; }
    .markdown-body .zeroclipboard-container, .markdown-body clipboard-copy { display: none; }
    .markdown-body .markdown-alert { padding: 8px 16px; border-left: .25em solid var(--border); }
    .markdown-body .markdown-alert-title { display: flex; align-items: center; gap: 8px; font-weight: 500; }
    .markdown-body .markdown-alert-title svg { fill: currentColor; }
    .markdown-body .markdown-alert-note { border-left-color: var(--accent); } .markdown-alert-note .markdown-alert-title { color: var(--accent); }
    .markdown-body .markdown-alert-tip { border-left-color: var(--success); } .markdown-alert-tip .markdown-alert-title { color: var(--success); }
    .markdown-body .markdown-alert-important { border-left-color: #8250df; } .markdown-alert-important .markdown-alert-title { color: #8250df; }
    .markdown-body .markdown-alert-warning { border-left-color: var(--attention); } .markdown-alert-warning .markdown-alert-title { color: var(--attention); }
    .markdown-body .markdown-alert-caution { border-left-color: var(--danger); } .markdown-alert-caution .markdown-alert-title { color: var(--danger); }
    .markdown-body .octicon { vertical-align: text-bottom; }

    .pl-c { color: #59636e; } .pl-k, .pl-kos + .pl-k { color: #cf222e; } .pl-s, .pl-pds, .pl-sr { color: #0a3069; }
    .pl-en, .pl-e { color: #6639ba; } .pl-c1, .pl-v, .pl-smi + .pl-c1 { color: #0550ae; } .pl-ent { color: #0550ae; }
    .pl-smi, .pl-s .pl-s1 { color: #1f2328; } .pl-mi1 { color: #116329; background: #dafbe1; } .pl-md { color: #82071e; background: #ffebe9; }
    .pl-mh, .pl-mh .pl-en { color: #0550ae; font-weight: bold; } .pl-bu, .pl-ii { color: #82071e; }
    @media (prefers-color-scheme: dark) {
      .pl-c { color: #9198a1; } .pl-k { color: #ff7b72; } .pl-s, .pl-pds, .pl-sr { color: #a5d6ff; }
      .pl-en, .pl-e { color: #d2a8ff; } .pl-c1, .pl-v, .pl-ent { color: #79c0ff; } .pl-smi, .pl-s .pl-s1 { color: #f0f6fc; }
      .pl-mi1 { color: #aff5b4; background: #033a16; } .pl-md { color: #ffdcd7; background: #67060c; }
      .pl-mh, .pl-mh .pl-en { color: #79c0ff; } .pl-bu, .pl-ii { color: #f85149; }
      .markdown-body .markdown-alert-important { border-left-color: #ab7df8; } .markdown-alert-important .markdown-alert-title { color: #ab7df8; }
    }
    """
}

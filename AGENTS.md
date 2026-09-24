# PR Viewer

Native macOS app to review GitHub pull requests. It replaces the GitHub web "Files changed" page for large pull requests.

## Core tenets: UX and performance

Every change must keep both. If a feature makes scrolling, opening a pull request, or typing slower, change the
feature.

- **Performance**
  - The diff scrolls at the display refresh rate with 300 files and 20,000 changed lines.
  - The main actor does no work that grows with the pull request size. Parse, diff, and highlight in background tasks.
  - Measure `DiffView` and `FileTree` changes with Instruments (Time Profiler, Hangs) before and after.
  - Draw text with Core Text in row views. Cache layouts; invalidate them only when width or appearance changes.
- **UX**
  - Match the GitHub "Files changed" layout and behavior, unless a change makes review faster.
  - Every frequent action has a keyboard shortcut.
  - Show data as it arrives. Do not block the window on a full load.

## UI framework rules

- Use AppKit (`NSTableView`, `NSOutlineView`) for content that can grow to thousands of rows.
- Use SwiftUI for the app shell, forms, and settings.
- Do not use SwiftUI `List` or `LazyVStack` for diff or file tree content.

## Modules

| Module            | Contents                                                     | Isolation   |
| ----------------- | ------------------------------------------------------------ | ----------- |
| `PRModels`        | Pull request, file, and review thread models; `PRRef` parsing | nonisolated |
| `ReviewRules`     | Glob patterns for tree collapse and auto-viewed files        | nonisolated |
| `DiffEngine`      | Patch parsing, split rows, word diff, highlighter protocol   | nonisolated |
| `SyntaxHighlight` | Tree-sitter implementation of `SyntaxHighlighting`           | nonisolated |
| `GitHubKit`       | Device flow sign-in, Keychain, REST and GraphQL client       | nonisolated |
| `FileTree`        | `NSOutlineView` file tree                                    | MainActor   |
| `DiffView`        | `NSTableView` split diff                                     | MainActor   |
| `PRDetail`        | Pull request screen: Summary and Files changed tabs          | MainActor   |
| `App/`            | App shell, sign-in, navigation, settings                     | MainActor   |

A module depends only on modules above it in this table. New screens (pull request lists, repository picker) are new
modules that `App/` routes to. They do not go into `PRDetail`.

## Commands

- `scripts/build.sh`: generate the Tuist project and build the app.
- `scripts/test.sh`: run unit tests.
- `scripts/run.sh`: build and open the app. In debug builds, `PRVIEWER_GITHUB_TOKEN` overrides sign-in.
- `scripts/format.sh`: format with `swift format`. `--lint` checks only.

## QA harness

Check every UI change with the harness before you report it done. Read the screenshots.

- Fixtures load a pull request with no network:
  - `Fixtures/synthetic-50`, `Fixtures/synthetic-300`: generated; committed.
  - `Fixtures/recorded/<name>`: recorded from GitHub; gitignored because they hold private code.
  - `scripts/fixtures.sh` rebuilds them. `prfixture record <link> --out <dir>` records one pull request.
- `scripts/shot.sh <fixture> <out.png> [args]`: loads the fixture, applies the args, writes a window PNG, and quits.
  `APPEARANCE=light` and `SIZE=1200x800` change the window.
- `scripts/perf.sh <fixture> [out.json]`: Release build. Scrolls the full diff on the display link and prints frame
  pacing. Keep `hitchTimeRatioMsPerSecond` under 5 on `Fixtures/synthetic-300`.
- App args: `--tab files|summary`, `--scroll-to-file <path>`, `--collapse-all`, `--toggle-viewed <path>`,
  `--rules '<ReviewRules JSON>'`, `--settle <seconds>`, `--open <link>`.
- Accessibility identifiers (`diff.table`, `fileTree.outline`, `address.field`, …) let computer-use tools drive the
  app.

## Code rules

- Swift 6 with complete strict concurrency.
- Test pure logic with Swift Testing. Each test must fail when the behavior it covers breaks.
- No comments unless the reason is not clear from the code. One line per comment.
- Write prose in ASD-STE100 Simplified Technical English.

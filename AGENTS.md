# PR Viewer

Native macOS app to review GitHub pull requests. It replaces the GitHub web "Files changed" page for large pull requests.

## Core tenets: UX and performance

Every change must keep both. If a feature makes scrolling, opening a pull request, or typing slower, change the
feature.

- **Performance:** the diff scrolls at the display refresh rate with 300 files and 20,000 changed lines. The main actor
  does no work that grows with the pull request size. Measure `DiffView` and `FileTree` changes with
  `scripts/perf.sh` before and after.
- **UX:** match the GitHub "Files changed" layout and behavior, unless a change makes review faster. Every frequent
  action has a keyboard shortcut. Show data as it arrives.

## Docs

Read the doc for the area you change:

- [docs/architecture.md](docs/architecture.md): modules, data flow, Viewed sync, content states, invariants.
- [docs/diff-rendering.md](docs/diff-rendering.md): the diff table design and the performance evidence behind it.
- [docs/github-api.md](docs/github-api.md): endpoints per feature, GitHub limits, Viewed semantics, sign-in.
- [docs/qa-harness.md](docs/qa-harness.md): fixtures, screenshots, perf benchmark, app arguments, safety rules.

## Modules

| Module            | Contents                                                      | Isolation   |
| ----------------- | ------------------------------------------------------------- | ----------- |
| `PRModels`        | Pull request, file, and review thread models; `PRRef` parsing | nonisolated |
| `ReviewRules`     | Glob patterns for tree collapse and auto-viewed files         | nonisolated |
| `DiffEngine`      | Patch parsing, split rows, word diff, expansion               | nonisolated |
| `SyntaxHighlight` | Tree-sitter implementation of `SyntaxHighlighting`            | nonisolated |
| `GitHubKit`       | `PullRequestService`, REST and GraphQL client, device flow    | nonisolated |
| `PRFixtures`      | Fixture store, offline service, synthetic generator           | nonisolated |
| `FileTree`        | `NSOutlineView` file tree                                     | MainActor   |
| `DiffView`        | `NSTableView` split diff                                      | MainActor   |
| `SignIn`          | `AuthSession` and sign-in view                                | MainActor   |
| `PRDetail`        | Pull request screen: Summary and Files changed tabs           | MainActor   |
| `App/`            | App shell, navigation, settings, QA harness                   | MainActor   |

A module depends only on modules above it in this table. New screens are new modules that `App/` routes to.

## Rules

- Use AppKit (`NSTableView`, `NSOutlineView`) for content that can grow to thousands of rows. Use SwiftUI for the shell,
  forms, and settings. Do not use SwiftUI `List` or `LazyVStack` for diff or tree content.
- Swift 6 with complete strict concurrency.
- Test pure logic and view-controller invariants with Swift Testing. Each test must fail when its behavior breaks.
- Check every UI change with `scripts/shot.sh` and read the screenshot before you report it done.
- Never run a harness action that writes (Viewed toggles, auto-viewed rules) against live GitHub. Use fixtures.
- No comments unless the reason is not clear from the code. One line per comment.
- Write prose in ASD-STE100 Simplified Technical English.

## Commands

- `scripts/build.sh`: generate the Tuist project and build. `CONFIGURATION=Release` for a Release build.
- `scripts/test.sh`: run all unit tests.
- `scripts/run.sh`: build and open the app. In debug builds, `PRVIEWER_GITHUB_TOKEN` skips sign-in.
- `scripts/shot.sh`, `scripts/perf.sh`, `scripts/fixtures.sh`: see [docs/qa-harness.md](docs/qa-harness.md).
- `scripts/format.sh`: format with `swift format`. `--lint` checks only.

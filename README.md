<img src="App/Resources/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="128" alt="">

# PR Viewer

A native macOS app to review GitHub pull requests. It replaces the GitHub web "Files changed" page for large pull requests.

## Setup

1. Install Xcode 26, [Tuist](https://tuist.dev) 4.64 or later, and `xcbeautify`.
2. Set the GitHub OAuth App client ID in `Project.swift` (`GITHUB_CLIENT_ID`). The OAuth App must have device flow
   turned on. A client ID is not a secret.
3. `tuist install`, then `scripts/run.sh`.

Debug builds skip sign-in when `PRVIEWER_GITHUB_TOKEN` is set, for example `PRVIEWER_GITHUB_TOKEN=$(gh auth token)`.

## Use

- Paste a pull request link into the address field (⌘L), or press ⇧⌘V to open the link on the clipboard.
- **Files changed** (⌘2): the file tree on the left, the split diff on the right.
- **Summary** (⌘1): the pull request description.

| Key            | Action                                           |
| -------------- | ------------------------------------------------ |
| `j` / `k`      | Next or previous file                            |
| `v`            | Toggle Viewed on the current file; syncs to GitHub |
| `x`            | Collapse or expand the current file              |
| Drag, then ⌘C  | Copy the selected lines of one side              |
| ⌥⌘[ / ⌥⌘]      | Collapse or expand all files                     |
| ⇧⌘B            | Show or hide the file tree                       |

Click a hunk header's gutter to show the unchanged lines above it. Click the last row of a file to show the lines below.

## Review rules

Settings (⌘,) holds one list of `.gitignore`-style globs. Matching files are marked Viewed on GitHub when a pull
request opens, so they collapse in the diff and dim in the file tree.

The default list covers tests, snapshots, test doubles, fixtures, generated files, and lockfiles. **Restore Defaults**
brings it back after an edit.

## Development

See [AGENTS.md](AGENTS.md) for the module map, the rules, and the QA harness.

The app icon comes from `Design/icon-artwork.png`. After you change the artwork, run
`swift scripts/icon.swift Design/icon-artwork.png App/Resources/Assets.xcassets/AppIcon.appiconset`.

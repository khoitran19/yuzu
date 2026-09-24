<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Design/logo-dark.png">
  <img src="Design/logo-light.png" width="270" alt="Yuzu">
</picture>

A native macOS app to review GitHub pull requests. It replaces the GitHub web "Files changed" page for large pull requests.

## Setup

1. Install Xcode 26, [Tuist](https://tuist.dev) 4.64 or later, and `xcbeautify`.
2. Set the GitHub OAuth App client ID in `Project.swift` (`GITHUB_CLIENT_ID`). The OAuth App must have device flow
   turned on. A client ID is not a secret.
3. `tuist install`, then `scripts/run.sh`.

Debug builds skip sign-in when `YUZU_GITHUB_TOKEN` is set, for example `YUZU_GITHUB_TOKEN=$(gh auth token)`.

## Use

- Paste a pull request link into the address field (⌘L), or press ⇧⌘V to open the link on the clipboard.
- **Files changed** (⌘2): the file tree on the left, the split diff on the right.
- **Summary** (⌘1): the pull request description.
- Links to GitHub pull requests open in the app. Other links open in the browser.

| Key            | Action                                           |
| -------------- | ------------------------------------------------ |
| `j` / `k`      | Next or previous file                            |
| `v`            | Toggle Viewed on the current file; syncs to GitHub |
| `x`            | Collapse or expand the current file              |
| `m`, ⇧⌘M       | Show or hide the Markdown preview                |
| Drag, then ⌘C  | Copy the selected lines of one side              |
| ⌥⌘[ / ⌥⌘]      | Collapse or expand all files                     |
| ⇧⌘B            | Show or hide the file tree                       |

Click a hunk header's gutter to show the unchanged lines above it. Click the last row of a file to show the lines below.

Click the preview button on a Markdown file header to see the rendered file next to the diff. Green bars mark changed
blocks and red marks show removed text. Click a bar to select its lines in the diff. In the preview, `n` and `p` go to
the next and previous change, and Esc closes it. The preview follows the diff to the next Markdown file.

## Review rules

Settings (⌘,) holds one list of `.gitignore`-style globs. Matching files are marked Viewed on GitHub when a pull
request opens, so they collapse in the diff and dim in the file tree.

The default list covers tests, snapshots, test doubles, fixtures, generated files, and lockfiles. **Restore Defaults**
brings it back after an edit.

## Development

See [AGENTS.md](AGENTS.md) for the module map, the rules, and the QA harness.

`swift scripts/brand.swift` draws the app icon and writes the App Icon set and the logos in `Design/`.

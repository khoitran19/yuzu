# QA harness

This document uses ASD-STE100 Simplified Technical English.

The harness lets an agent check its own UI work: it loads a pull request with no network, applies actions, then writes a
screenshot or a frame-time report and quits.

## Fixtures

| Fixture | Contents | Committed |
| --- | --- | --- |
| `Fixtures/synthetic-50` | 50 files, 1,000 changed lines, threads, mixed viewed states | Yes |
| `Fixtures/synthetic-300` | 300 files, 20,000 changed lines; the performance benchmark | Yes |
| `Fixtures/recorded/<name>` | A real pull request recorded from GitHub | No: it holds private code |

- `scripts/fixtures.sh` rebuilds all fixtures.
- `prfixture record <link> --out Fixtures/recorded/<name>` records one pull request with the base (merge base) and head
  contents of every file.
- The synthetic generator is deterministic: the same seed gives the same bytes. Its patches are real diffs of its
  generated contents, so expansion works on them.

## Screenshots

```sh
scripts/shot.sh Fixtures/synthetic-50 .build/shots/x.png [app args]
APPEARANCE=light SIZE=1200x800 NO_BUILD=1 scripts/shot.sh …
```

The window renders in process (`cacheDisplay`), so it needs no screen-recording permission and works while the display
sleeps. Read the PNG after every UI change.

The capture draws web views last. With `--pr-list` and `--tab summary`, the Summary page covers the panel in the PNG,
but not in the live window. Use the Files changed tab for panel screenshots.

## App arguments

| Argument | Effect |
| --- | --- |
| `--fixture <dir>` | Use `FixturePullRequestService`; skip sign-in |
| `--open <link>` | Open this pull request (with a token, this is the live GitHub path) |
| `--tab files\|summary` | Select a tab |
| `--pr-list mine\|others` | Open the pull request panel on this tab. Fixtures serve synthetic rows |
| `--pr-list-empty` | The fixture serves no open pull requests, for the empty state |
| `--scroll-to-file <path>` | Scroll the diff to a file |
| `--summary-scroll <y\|bottom>` | Scroll the Summary page |
| `--summary-click <css selector>` | Click an element on the Summary page, such as a link or a sidebar button (`'[data-action=enqueue]'`). It runs in the `summarySidebar` world, because the sidebar ignores clicks from page scripts |
| `--merge-status <preset>` | Replace the fixture's merge box state: `clean`, `blocked` (the default), `queued`, `auto-merge`, `draft`, `conflicts`, `merged`, `author`, `queue-enabled`, `no-permission`, `new-commits` (GitHub reports another head, so the "New commits were
pushed" notice shows). `clean` also makes all checks pass. Actions then change only the fixture in memory |
| `--open-tab <link>` | After the load, open this pull request in a new tab (repeatable). A fixture serves only its own pull request, so other tabs show the load error |
| `--submit <text>` | After the tabs open, submit this text in the address field, such as `@rik`. In a fixture, `@rik` gives the Mine rows and the fixture pull request |
| `--key <combo>` | After the tabs open, send a key combination such as `shift+cmd+]` to the main menu (repeatable). Logs the selected tab |
| `--collapse-all` | Collapse every file |
| `--settings` | Open Settings; with `--screenshot`, capture it and quit |
| `--preview <path>` | Open the Markdown preview of a file |
| `--preview-script '<js>'` | Run JavaScript in the preview's gutter world (for example `step(1)`); logs the result |
| `--settings-tab rules\|shortcuts` | Open Settings on this tab; implies `--settings`. `--settings --settings-tab shortcuts` opens no window, so do not put `--settings` before it |
| `--toggle-viewed <path>` | Toggle Viewed (repeatable) |
| `--expand <path>:<hunk\|tail>` | Expand context above a hunk, or the tail (repeatable) |
| `--rules '<ReviewRules JSON>'` | Use these rules. Without it, a harness run uses no rules (`--settings` shows the defaults). Rules stay in a scratch defaults domain, never in the user's settings |
| `--settle <seconds>` | Wait before the capture (default 1) |
| `--latency <ms>` | Delay every fixture response, to simulate the network |
| `--screenshot <png>` | Capture and quit. With no session, captures the sign-in screen |
| `--perf-scroll <json>` | Run the scroll benchmark and quit |

Controls have accessibility identifiers (`diff.table`, `fileTree.outline`, `fileTree.filter`, `address.field`,
`prDetail.tab.files`, `prDetail.state`, `signIn.button`, `prList.toggle`, `prList.panel`, `prList.tab`, `reviewSheet`,
`reviewSheet.editor`, `reviewSheet.submit`, `mergeSheet`, `mergeSheet.method`, `mergeSheet.headline`, `mergeSheet.body`,
`mergeSheet.confirm`), so computer-use tools can drive the app. Sidebar buttons in the Summary page have a `data-action`
attribute, for example `approve`, `merge`, `enqueue`, and `bypassMerge`.

The window capture does not include sheets. To see a running action, add `--latency 2500` and click a button that runs
at once, for example `--merge-status queue-enabled --summary-click '[data-action=enqueue]'`.

## Performance

```sh
scripts/perf.sh Fixtures/synthetic-300 .build/perf.json
```

The `loaded` log line has `firstPaintMs` (diff on screen) and `loadMs` (all parts arrived).

The benchmark scrolls the diff at 6,000 pt/s for up to 30 s and writes JSON:

- `displayLink` mode (display awake): frame time is the time between display-link callbacks.
- `forcedDisplay` mode (display asleep or headless): each step scrolls, forces a synchronous redraw, and times the main
  thread against a 120 Hz budget (8.3 ms). This is stricter than the display-link mode.
- `hitchTimeRatioMsPerSecond` is Apple's hitch metric: under 5 is good, over 10 is poor.
- Frames over 1.5× the budget print `[harness] slow <ms> at <offset>: <visible rows>`. Row codes: `H` header,
  `@` hunk, `L` line, `T` thread, `N` notice, `E` expand, `F` footer. A number after a code is a row height over 40 pt.

Run perf with no other heavy process on the machine; a parallel build or review changes the numbers by 2×.

## Safety

- The harness with `--open` and a token uses real GitHub. `--toggle-viewed` and auto-viewed rules then write to the
  user's Viewed state. A `--summary-click` on a sidebar button can approve, merge, or enqueue a real pull request. Use
  fixtures for any action that writes.
- On 2026-09-24 a harness run saved its test rules to the user's settings. A later live run then marked 3 files Viewed
  on GitHub. `--rules` now uses a scratch defaults domain.
- The app has default auto-viewed rules. A harness run ignores the user's rules and the defaults, so a live `--open`
  run writes nothing unless you pass `--rules`.

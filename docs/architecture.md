# Architecture

This document uses ASD-STE100 Simplified Technical English.

## Modules

```mermaid
flowchart LR
    subgraph Shell["App (SwiftUI)"]
        App[App shell<br/>address bar, routes, settings]
        Harness[QA harness]
    end
    subgraph Screens["Screens (MainActor)"]
        PRDetail[PRDetail<br/>Summary + Files changed]
        SignIn[SignIn<br/>device flow UI]
    end
    subgraph Views["AppKit views (MainActor)"]
        FileTree[FileTree<br/>NSOutlineView]
        DiffView[DiffView<br/>NSTableView]
    end
    subgraph Core["Core (nonisolated, Sendable)"]
        GitHubKit[GitHubKit<br/>REST + GraphQL, Keychain]
        DiffEngine[DiffEngine<br/>patch, split rows, word diff]
        SyntaxHighlight[SyntaxHighlight<br/>tree-sitter]
        ReviewRules[ReviewRules<br/>globs]
        PRModels[PRModels]
        PRFixtures[PRFixtures<br/>offline service]
    end
    App -->|routes to| PRDetail
    App -->|shows when signed out| SignIn
    Harness -->|drives| PRDetail
    PRDetail -->|hosts| FileTree
    PRDetail -->|hosts| DiffView
    PRDetail -->|PullRequestService| GitHubKit
    PRDetail -->|builds FileDiff| DiffEngine
    PRDetail -->|SyntaxHighlighting| SyntaxHighlight
    FileTree -->|collapse rules| ReviewRules
    DiffView -->|renders| DiffEngine
    App -->|fixture mode| PRFixtures
    PRFixtures -->|implements| GitHubKit
```

- A module depends only on modules at its level or lower. `AGENTS.md` has the table.
- `PRDetail` talks to GitHub only through `PullRequestService`. `GitHubClient` and `FixturePullRequestService` implement
  it, so the harness and the tests use the same screen code as production.
- New screens (a pull request list, a repository picker) are new modules that `App` routes to.

## Open a pull request

```mermaid
sequenceDiagram
    actor User
    participant App
    participant Model as PRDetailModel
    participant Service as PullRequestService
    participant Tree as FileTree
    participant Diff as DiffView
    participant BG as Background tasks

    User->>App: Paste link (PRRef parses it)
    App->>Model: init(ref, service, rules)
    Model->>Service: snapshot(of:)
    Note over Service: GraphQL detail, viewed states, threads<br/>and REST files pages run in parallel
    Service-->>Model: PullRequestSnapshot
    Model->>Model: Apply auto-viewed rules
    Model->>Tree: setFiles (returns display order)
    Model->>BG: Build FileDiff for each file
    BG-->>Model: [DiffFileItem] in tree order
    Model->>Diff: setFiles
    Model->>BG: Highlight stream (parallel)
    loop Every 50 ms
        BG-->>Model: Batch of highlights
        Model->>Diff: updateHighlights (visible rows redraw)
    end
    Model->>Service: setViewed(true, auto-viewed paths)
```

The diff shows before highlighting finishes. Highlights recolor visible rows as batches arrive.

## Viewed state

```mermaid
sequenceDiagram
    actor User
    participant Diff as DiffView / FileTree
    participant Model as PRDetailModel
    participant GitHub

    User->>Diff: Click Viewed (or press v)
    Diff->>Model: setViewed(path, true)
    Model->>Diff: Apply now (collapse file, check tree row)
    Model->>Model: generation[path] += 1
    Model->>GitHub: markFileAsViewed (queued after earlier requests)
    alt Success
        GitHub-->>Model: OK
        Model->>Model: confirmed[path] = true
    else Failure or partial failure
        GitHub-->>Model: Error (failed paths)
        Model->>Model: Revert failed paths to confirmed state,<br/>only if generation has not changed
        Model->>Diff: Show error banner
    end
```

## File content states

```mermaid
stateDiagram-v2
    [*] --> Diff: patch present
    [*] --> TooLarge: patch omitted, lines changed
    [*] --> Binary: patch omitted, no line counts
    [*] --> Unchanged: rename or copy without changes
    TooLarge --> Loading: Load diff
    Loading --> Diff: both versions are text
    Loading --> Binary: a version is not text
    Loading --> Failed: request error
    Diff --> Diff: expand gap or tail
```

Each transition installs new content and increments the file's content generation.

## Invariants

- **Content generation.** Every content change of a file increments `generations[path]`. A highlight or expansion result
  for an older generation is dropped. This prevents wrong colors after an expansion changes line indexes.
- **One expansion at a time per file.** Expansions of one file run in order. Each finds its hunk by the hunk's first
  new-side line, not by index, because an earlier expansion can merge hunks.
- **Viewed requests run in order.** A failed request reverts only the paths that failed, and only if the user did not
  change them after the request. It reverts to the state GitHub last confirmed.
- **Tree order is diff order.** `FileTree.orderedFilePaths` gives the order: folders first, then files, sorted without
  case. `DiffItemFactory` sorts the diff to match, as GitHub does.
- **Scroll sync never opens a folder.** `FileTree.reveal` selects the closest visible folder when a collapsed folder hides
  the file. This keeps the collapse rules in effect.
- **Full diffs compare against the merge base,** not the base branch tip. GitHub pull request diffs use the merge base.

# GitHub API use

This document uses ASD-STE100 Simplified Technical English.

## Endpoints per feature

| Feature | Endpoint | Notes |
| --- | --- | --- |
| Title, state, branches, body | GraphQL `pullRequest { title state bodyHTML baseRefOid headRefOid … }` | `bodyHTML` is GitHub's rendered markdown; the Summary tab shows it in a web view. |
| Files and patches | REST `GET /repos/{o}/{r}/pulls/{n}/files?per_page=100&page=N` | Page 1 starts at once. Its `Link` header (`rel="last"`) gives the page count; the other pages load in parallel. |
| Viewed state (read) | GraphQL `pullRequest { id files { path viewerViewedState } }` | Paginated by cursor. Returns the node ID, so the file list does not wait for the details request. |
| Viewed state (write) | GraphQL `markFileAsViewed` / `unmarkFileAsViewed` | Many paths in one request, one alias (`m0`, `m1`, …) per path. |
| Summary timeline | GraphQL `timelineItems(itemTypes: [ISSUE_COMMENT, PULL_REQUEST_REVIEW])` with review `comments { diffHunk replyTo }` | Event rows (commits, labels, deployments) are not requested. A review that only replies to threads is not shown; its replies show under the first comment of the thread. |
| Summary checks | GraphQL `commits(last: 1) { statusCheckRollup { contexts } }` | `CheckRun` and `StatusContext`, paginated by cursor, with `isRequired(pullRequestNumber:)`. While a check runs, this request repeats every 15 s; it stops when all checks finish or the pull request closes. |
| Avatars | `avatarUrl(size: 80)`, served to the Summary web view through the `prv-avatar:` scheme | `AvatarCache` keeps each image in `~/Library/Caches/dev.khoitran.prviewer/Avatars`. A copy older than 7 days is shown, then refreshed in the background. |
| Review threads | GraphQL `reviewThreads { line startLine diffSide isResolved isOutdated comments }` | Comments over 100 per thread load through `node(id:)`. |
| Full file contents | REST `GET /repos/{o}/{r}/contents/{path}?ref={oid}` with `Accept: application/vnd.github.raw+json` | For "Load diff" and context expansion. |
| Merge base | REST `GET /repos/{o}/{r}/compare/{base}...{head}?per_page=1&page=2` | Page 2 leaves out the file list, so the response is small. |
| Open pull request panel | GraphQL `search(type: ISSUE, query: "repo:o/r is:pr is:open author:@me sort:updated-desc")`, and `-author:@me` for Others | 50 per page, at most 2 pages (100 rows) per tab. `issueCount` gives the tab count. Checks come from `commits(last: 1) { statusCheckRollup { state } }`. |
| Sign-in | `POST github.com/login/device/code`, then poll `login/oauth/access_token` | Scope `repo`. The token is stored in the Keychain. |

## Limits

- **3,000 files.** The files endpoint returns at most 3,000 files. The app shows a banner with the number of files it
  cannot show.
- **Omitted patches.** GitHub leaves out `patch` for large diffs and binary files. With 0 additions and 0 deletions the
  app shows "Binary file"; otherwise it shows "Load diff", which diffs the two full versions locally.
- **Outdated threads** (`line == nil`) do not show in the diff. GitHub shows them only on the Conversation page.
- **Rate limit.** Opening a pull request costs 5 GraphQL requests (detail, viewed states, threads, timeline, checks) plus one REST request
  per 100 files. Expansion and "Load diff" cost 1–3 requests per file. Opening the pull request panel costs 2–4 GraphQL
  requests.
- **Response time.** On #6663 (22 files): files 0.46 s, Viewed states 0.49 s, details 0.75 s, threads 0.91 s. The first
  paint waits for the first two only: about 0.6 s.

## Viewed-state semantics

- Viewed state belongs to the signed-in user. Other reviewers do not see it.
- `DISMISSED` means the user viewed the file, then the file changed. The app shows it as not viewed.
- A mutation with many aliases can succeed for some paths and fail for others. `GitHubClient.setViewed` maps each error's
  `path[0]` alias to its file and throws `GitHubError.partialFailure(paths:)` with only the failed paths.
- Auto-viewed rules write to GitHub when a pull request opens. Do not run the harness against GitHub with auto-viewed
  rules (see [qa-harness.md](qa-harness.md)).

## Authentication

- Release builds use the OAuth device flow. The client ID is the `GITHUB_CLIENT_ID` build setting in `Project.swift`.
  The app needs no client secret.
- Organizations with OAuth App restrictions must approve the app before it can read their repositories.
- Debug builds use `PRVIEWER_GITHUB_TOKEN` when it is set, and do not save it to the Keychain.

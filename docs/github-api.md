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
| Summary checks and merge box (`status(of:)`) | GraphQL `commits(last: 1) { statusCheckRollup { contexts } }`, plus on page 1 only (`@include(if: $first)`): `state isDraft headRefOid mergeable mergeStateStatus reviewDecision viewerDidAuthor viewerCanUpdate viewerCanMergeAsAdmin viewerCanEnableAutoMerge viewerCanDisableAutoMerge viewerLatestReview { state } isMergeQueueEnabled mergeQueueEntry { position state estimatedTimeToMerge enqueuedAt } mergeQueue { url entries { totalCount } } autoMergeRequest { mergeMethod enabledBy { login } }` and repository `viewerPermission mergeCommitAllowed squashMergeAllowed rebaseMergeAllowed viewerDefaultMergeMethod autoMergeAllowed` | `CheckRun` and `StatusContext`, paginated by cursor, with `isRequired(pullRequestNumber:)`. The merge fields cost no extra request. Write, maintain, or admin permission means the viewer can merge. See [Status polling](architecture.md#summary-sidebar-and-pull-request-actions). |
| Approve, Request changes | GraphQL `addPullRequestReview(input: {pullRequestId, event: APPROVE \| REQUEST_CHANGES, body})` | An empty Approve comment is left out. Then `conversation(of:)` reloads the timeline and the merge box. |
| Merge now, bypass merge | GraphQL `mergePullRequest(input: {pullRequestId, mergeMethod, expectedHeadOid, commitHeadline, commitBody})` | `expectedHeadOid` is the head of the loaded diff, so GitHub refuses a merge of commits the viewer did not review. An empty headline or body is left out, so GitHub uses the repository default. Rebase sends neither. |
| Enable or disable auto-merge | GraphQL `enablePullRequestAutoMerge(input: {pullRequestId, mergeMethod, expectedHeadOid})`, `disablePullRequestAutoMerge(input: {pullRequestId})` | |
| Merge queue | GraphQL `enqueuePullRequest(input: {pullRequestId, expectedHeadOid})`, `dequeuePullRequest(input: {id})` | `DequeuePullRequestInput` names the pull request `id`, not `pullRequestId`. |
| Draft | GraphQL `markPullRequestReadyForReview(input: {pullRequestId})`, `convertPullRequestToDraft(input: {pullRequestId})` | |
| Avatars | `avatarUrl(size: 80)`, served to the Summary web view through the `yuzu-avatar:` scheme | `AvatarCache` keeps each image in `~/Library/Caches/dev.khoitran.yuzu/Avatars`. A copy older than 7 days is shown, then refreshed in the background. |
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
- **Rate limit.** Opening a pull request costs 5 GraphQL requests (detail, viewed states, threads, timeline, status) plus one REST request
  per 100 files. Each sidebar action costs 2 requests: the mutation and one status refresh (a review reloads the timeline
  too, so it costs 3). Polling costs 1 request per 15 s while checks run, the pull request is queued, or auto-merge is on,
  and at most 5 requests at 3 s while mergeability is unknown.
- **Mutation errors.** GitHub returns refused actions as GraphQL errors. `GitHubClient.perform` throws
  `GitHubError.rejected` with GitHub's message, and the banner shows "Could not merge: <message>". Expansion and "Load diff" cost 1–3 requests per file. Opening the pull request panel costs 2–4 GraphQL
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
- Debug builds use `YUZU_GITHUB_TOKEN` when it is set, and do not save it to the Keychain.

# Backlog

This document uses ASD-STE100 Simplified Technical English.

## Disk cache for reopened pull requests

Deferred on 2026-09-24. The first paint is now about 0.6 s, and all of it is GitHub response time. A cache is the only
way to make a reopened pull request show at once.

Design, from the first attempt:

- `SnapshotCache` in `GitHubKit`: one binary property list per pull request in `~/Library/Caches/<bundle id>/snapshots`,
  the 60 most recent kept. Read and write off the main actor.
- `PRDetailModel.load()` draws the cached snapshot, then merges live parts. `receiveFiles` already supports a second
  delivery: when files and patches match what is on screen, only Viewed states change and no rows rebuild.
- Three rules keep it simple:
  1. The cache only draws the first frame. Live data always replaces it.
  2. Viewed changes made since opening win over cached and live states (the Viewed generation counter tracks them).
  3. Same files and patches: no row rebuild. Different: rebuild and keep the scroll position.
- Save the cache after each confirmed Viewed change, so a reopen does not collapse or expand files after the first
  paint.
- Harness runs must never read or write the user's cache: use a scratch directory or no cache.

import Foundation
import ReviewRules
import Testing

struct ReviewRulesTests {
    @Test(arguments: [
        "apps/platform/connections/src/__tests__/provisioning.spec.ts",
        "apps/platform/assistant-web/src/features/Composer.spec.tsx",
        ".claude/hooks/disable-fsmonitor.test.sh",
        "packages/platform/board-kit/wrangler.test.jsonc",
        "apps/platform/district-api/src/__integration__/nativeGateway.e2e.ts",
        "packages/platform/db/src/__tests__/__snapshots__/privileges.spec.ts.snap",
        "apps/platform/connections/src/testing/fakeKernelApi.ts",
        "apps/platform/boards/src/testing/fakeBuilderSandbox.ts",
        "apps/platform/live-engine/src/adapter/mock/MockAuctionAdapter.ts",
        "prototypes/live-auctions/apps/shopify-auction-adapter/src/__tests__/fake-shopify/fakeConnections.ts",
        "apps/platform/assistant-web/setup-tests.ts",
        "apps/platform/boards/vitest.publish.config.ts",
        "apps/web/live-web/src/__classic/__generated/graphql/gql.ts",
        "apps/platform/connections/worker-configuration.d.ts",
        "pnpm-lock.yaml",
        "agents.lock",
    ])
    func defaultsMarkLowSignalFiles(_ path: String) {
        #expect(ReviewRules.defaults.matcher.isAutoViewed(file: path))
    }

    @Test(arguments: [
        "apps/platform/connections/src/provisioning/withProvisioningLock.ts",
        "packages/platform/files/src/lockFile.ts",
        "apps/platform/connection-provisioning/src/stubs/sharp.ts",
        "docs/superpowers/specs/2026-09-12-browser-connections-design.md",
        "packages/platform/db/scripts/buildPgliteSnapshot.ts",
        "packages/build-config/src/vitest.ts",
        "packages/db/migrations/20260920_add_index.sql",
        "apps/platform/connections/package.json",
    ])
    func defaultsKeepSourceFiles(_ path: String) {
        #expect(!ReviewRules.defaults.matcher.isAutoViewed(file: path))
    }

    @Test func matchReportsFirstMatchingPattern() {
        let matcher = ReviewRules(autoViewed: ["# Tests", "__tests__/", "*.spec.ts"]).matcher
        #expect(matcher.autoViewedPattern(file: "src/__tests__/a.spec.ts") == "__tests__/")
        #expect(matcher.autoViewedPattern(file: "src/a.ts") == nil)
    }

    @MainActor @Test func storeStartsWithDefaultsAndKeepsSavedRules() throws {
        let name = "dev.khoitran.prviewer.ReviewRulesTests"
        let storage = try #require(UserDefaults(suiteName: name))
        storage.removePersistentDomain(forName: name)
        defer { storage.removePersistentDomain(forName: name) }

        #expect(ReviewRulesStore(storage: storage).rules == .defaults)

        ReviewRulesStore(storage: storage).rules = ReviewRules()
        #expect(ReviewRulesStore(storage: storage).rules == ReviewRules())
    }

    @Test func decodesRulesSavedWithTreeCollapsePatterns() throws {
        let json = #"{"collapsedInTree":["migrations"],"autoViewed":["*.spec.ts"]}"#
        let rules = try JSONDecoder().decode(ReviewRules.self, from: Data(json.utf8))
        #expect(rules == ReviewRules(autoViewed: ["*.spec.ts"]))
    }
}

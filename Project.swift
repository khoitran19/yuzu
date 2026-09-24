import ProjectDescription

let bundleIdPrefix = "dev.khoitran.prviewer"
let destinations: Destinations = [.mac]
let deployment: DeploymentTargets = .macOS("15.0")

enum Isolation { case nonisolated, mainActor }

func settings(_ isolation: Isolation) -> Settings {
    var base: SettingsDictionary = [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    ]
    if isolation == .mainActor { base["SWIFT_DEFAULT_ACTOR_ISOLATION"] = "MainActor" }
    return .settings(base: base)
}

func module(
    _ name: String,
    isolation: Isolation,
    dependencies: [TargetDependency] = [],
    tests: Bool = false,
    resources: ResourceFileElements? = nil
) -> [Target] {
    var targets: [Target] = [
        .target(
            name: name,
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundleIdPrefix).\(name)",
            deploymentTargets: deployment,
            sources: ["Modules/\(name)/Sources/**"],
            resources: resources,
            dependencies: dependencies,
            settings: settings(isolation)
        ),
    ]
    if tests {
        targets.append(.target(
            name: "\(name)Tests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundleIdPrefix).\(name)Tests",
            deploymentTargets: deployment,
            sources: ["Modules/\(name)/Tests/**"],
            dependencies: [.target(name: name)],
            settings: settings(isolation)
        ))
    }
    return targets
}

let app: Target = .target(
    name: "PRViewer",
    destinations: destinations,
    product: .app,
    bundleId: bundleIdPrefix,
    deploymentTargets: deployment,
    infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": "PR Viewer",
        "LSApplicationCategoryType": "public.app-category.developer-tools",
        "GitHubClientID": "$(GITHUB_CLIENT_ID)",
    ]),
    sources: ["App/Sources/**"],
    resources: ["App/Resources/**"],
    dependencies: [
        .target(name: "PRDetail"),
        .target(name: "SignIn"),
        .target(name: "PRFixtures"),
        .target(name: "GitHubKit"),
        .target(name: "ReviewRules"),
        .target(name: "PRModels"),
        .target(name: "DiffEngine"),
        .target(name: "SyntaxHighlight"),
    ],
    settings: .settings(base: [
        "SWIFT_VERSION": "6.0",
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
        "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
        "GITHUB_CLIENT_ID": "",
    ])
)

var targets: [Target] = [app]
targets += module("PRModels", isolation: .nonisolated, tests: true)
targets += module("ReviewRules", isolation: .nonisolated, tests: true)
targets += module("DiffEngine", isolation: .nonisolated, dependencies: [.target(name: "PRModels")], tests: true)
targets += module("SyntaxHighlight", isolation: .nonisolated, dependencies: [
    .target(name: "DiffEngine"),
    .external(name: "TreeSitter"),
    .external(name: "TreeSitterBash"),
    .external(name: "TreeSitterCSS"),
    .external(name: "TreeSitterGo"),
    .external(name: "TreeSitterJavaScript"),
    .external(name: "TreeSitterJSON"),
    .external(name: "TreeSitterMarkdown"),
    .external(name: "TreeSitterPython"),
    .external(name: "TreeSitterRust"),
    .external(name: "TreeSitterSql"),
    .external(name: "TreeSitterSwift"),
    .external(name: "TreeSitterTypeScript"),
    .external(name: "TreeSitterYAML"),
], tests: true, resources: ["Modules/SyntaxHighlight/Resources/**"])
targets += module("GitHubKit", isolation: .nonisolated, dependencies: [.target(name: "PRModels")], tests: true)
targets += module("PRFixtures", isolation: .nonisolated, dependencies: [
    .target(name: "PRModels"),
    .target(name: "GitHubKit"),
], tests: true).map { target in
    var target = target
    if target.name == "PRFixturesTests" { target.dependencies.append(.target(name: "DiffEngine")) }
    return target
}
targets += module("SignIn", isolation: .mainActor, dependencies: [.target(name: "GitHubKit"), .target(name: "PRModels")], tests: true)
targets += module("FileTree", isolation: .mainActor, dependencies: [
    .target(name: "PRModels"),
    .target(name: "ReviewRules"),
], tests: true)
targets += module("DiffView", isolation: .mainActor, dependencies: [
    .target(name: "DiffEngine"),
    .target(name: "PRModels"),
], tests: true)
targets += module("PRDetail", isolation: .mainActor, dependencies: [
    .target(name: "PRModels"),
    .target(name: "ReviewRules"),
    .target(name: "DiffEngine"),
    .target(name: "SyntaxHighlight"),
    .target(name: "GitHubKit"),
    .target(name: "FileTree"),
    .target(name: "DiffView"),
])

targets.append(.target(
    name: "prfixture",
    destinations: destinations,
    product: .commandLineTool,
    bundleId: "\(bundleIdPrefix).prfixture",
    deploymentTargets: deployment,
    sources: ["Tools/prfixture/Sources/**"],
    dependencies: [
        .target(name: "PRFixtures"),
        .target(name: "GitHubKit"),
        .target(name: "PRModels"),
    ],
    settings: .settings(base: settings(.nonisolated).base.merging(["LD_RUNPATH_SEARCH_PATHS": "$(inherited) @executable_path"]) { $1 })
))

let project = Project(name: "PRViewer", targets: targets)

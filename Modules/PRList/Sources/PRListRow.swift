import AppKit
import PRDetail
import PRModels
import SwiftUI

struct PRListRow: View {
    let pullRequest: PullRequestSummary
    let showsAuthor: Bool
    let isCurrent: Bool
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(nsImage: (pullRequest.isDraft ? Octicon.gitPullRequestDraft : Octicon.gitPullRequest).image)
                    .foregroundStyle(pullRequest.isDraft ? Color.secondary : Color.green)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 4) {
                    title
                    Text(meta)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let review = pullRequest.reviewDecision { ReviewChip(decision: review) }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 6) {
                    AvatarView(actor: pullRequest.author, size: 20)
                    if pullRequest.commentCount > 0 {
                        HStack(spacing: 3) {
                            Image(nsImage: Octicon.comment.image).resizable().frame(width: 12, height: 12)
                            Text(pullRequest.commentCount, format: .number)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help("\(pullRequest.commentCount) comments")
                    }
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(alignment: .leading) {
                if isCurrent { Rectangle().fill(Color.accentColor).frame(width: 3) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var title: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(pullRequest.title)
                .font(.body.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            if let checks = pullRequest.checks { ChecksIcon(state: checks) }
        }
    }

    private var meta: String {
        let updated = pullRequest.updatedAt.formatted(.relative(presentation: .named))
        var parts = ["#\(pullRequest.ref.number)", "updated \(updated)"]
        if showsAuthor { parts.append("by \(pullRequest.author?.login ?? "ghost")") }
        return parts.joined(separator: " · ")
    }

    private var background: some ShapeStyle {
        if isSelected { return AnyShapeStyle(Color.accentColor.opacity(0.16)) }
        if isCurrent { return AnyShapeStyle(Color.accentColor.opacity(0.07)) }
        if hovering { return AnyShapeStyle(.quaternary.opacity(0.6)) }
        return AnyShapeStyle(.clear)
    }
}

private struct ChecksIcon: View {
    let state: PullRequestSummary.ChecksState

    var body: some View {
        let (icon, color, help): (Octicon, Color, String) =
            switch state {
            case .success: (.check, .green, "All checks passed")
            case .failure: (.x, .red, "Some checks failed")
            case .pending: (.dotFill, .orange, "Checks are running")
            }
        Image(nsImage: icon.image)
            .resizable()
            .frame(width: 13, height: 13)
            .foregroundStyle(color)
            .help(help)
    }
}

private struct ReviewChip: View {
    let decision: PullRequestSummary.ReviewDecision

    var body: some View {
        let (title, color): (String, Color) =
            switch decision {
            case .approved: ("Approved", .green)
            case .changesRequested: ("Changes requested", .red)
            case .reviewRequired: ("Review required", .secondary)
            }
        Text(title)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .overlay(Capsule().strokeBorder(color.opacity(0.5)))
    }
}

private struct AvatarView: View {
    let actor: Actor?
    let size: CGFloat
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable()
            } else {
                Circle()
                    .fill(.quaternary)
                    .overlay {
                        Text(actor?.login.prefix(1).uppercased() ?? "?")
                            .font(.system(size: size * 0.5, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .help(actor?.login ?? "ghost")
        .task(id: actor?.avatarURL) {
            guard let url = actor?.avatarURL, let data = try? await AvatarCache.shared.data(for: url) else { return }
            image = NSImage(data: data)
        }
    }
}

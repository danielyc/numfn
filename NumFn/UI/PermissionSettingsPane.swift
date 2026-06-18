import SwiftUI

struct PermissionSettingsPane: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                SettingsPane(
                    title: "Permissions",
                    subtitle: "Set up the access NumFn needs to remap keys.",
                    symbolName: SettingsSection.permissions.symbolName,
                    tint: SettingsSection.permissions.tint
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        permissionOverview
                        actionCards(width: geometry.size.width)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var permissionOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    overviewHeader

                    Spacer(minLength: 12)

                    PermissionStatusPill(
                        label: "Accessibility permission",
                        value: permissionStatusTitle,
                        color: permissionStatusColor
                    )
                }

                VStack(alignment: .leading, spacing: 14) {
                    overviewHeader
                    PermissionStatusPill(
                        label: "Accessibility permission",
                        value: permissionStatusTitle,
                        color: permissionStatusColor
                    )
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(permissionStatusColor.opacity(0.18))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }

    private var overviewHeader: some View {
        HStack(alignment: .top, spacing: 18) {
            SymbolBadge(symbolName: permissionSymbolName, tint: permissionStatusColor, size: 48)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(permissionHeadline)
                    .font(.title2.bold())

                Text(permissionSummary)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func actionCards(width: CGFloat) -> some View {
        if width >= 760 {
            HStack(alignment: .top, spacing: 16) {
                primaryActions
                    .frame(maxWidth: .infinity, alignment: .top)

                setupHelp
                    .frame(maxWidth: .infinity, alignment: .top)
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                primaryActions
                setupHelp
            }
        }
    }

    private var primaryActions: some View {
        PermissionCard("Actions") {
            PermissionActionRow(
                symbolName: "checkmark.shield",
                tint: permissionStatusColor,
                title: appState.hasAccessibilityPermission ? "Accessibility is allowed" : "Allow Accessibility",
                detail: appState.hasAccessibilityPermission
                    ? "NumFn is allowed to remap keys on this Mac."
                    : "Ask macOS to allow NumFn to remap keys."
            ) {
                permissionRequestButton
            }

            PermissionActionRow(
                symbolName: "gearshape",
                tint: SettingsSection.permissions.tint,
                title: "System Settings",
                detail: "Open Privacy & Security in System Settings."
            ) {
                Button {
                    appState.openAccessibilitySettings()
                } label: {
                    Label("Open", systemImage: "arrow.up.right.square")
                }
            }

            HStack {
                Spacer()

                Button {
                    appState.refreshPermissions()
                } label: {
                    Label("Refresh Status", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private var setupHelp: some View {
        PermissionCard("Setup Guide") {
            PermissionActionRow(
                symbolName: "list.bullet.rectangle",
                tint: SettingsSection.permissions.tint,
                title: "Setup walkthrough",
                detail: "Review permissions, controls, and privacy."
            ) {
                Button {
                    appState.showOnboardingHelp()
                } label: {
                    Label("Show", systemImage: "questionmark.circle")
                }
            }

            if !appState.hasAccessibilityPermission {
                PermissionNotice(
                    symbolName: "exclamationmark.triangle.fill",
                    text: "NumFn will stay paused until you allow Accessibility access.",
                    tint: .orange
                )
            }
        }
    }

    @ViewBuilder
    private var permissionRequestButton: some View {
        if appState.hasAccessibilityPermission {
            Button {
                appState.requestAccessibilityPermission()
            } label: {
                Label("Check Again", systemImage: "checkmark.shield")
            }
        } else {
            Button {
                appState.requestAccessibilityPermission()
            } label: {
                Label("Allow", systemImage: "checkmark.shield")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var permissionHeadline: String {
        appState.hasAccessibilityPermission ? "Accessibility is setup correctly." : "Accessibility is needed"
    }

    private var permissionStatusTitle: String {
        appState.hasAccessibilityPermission ? "Allowed" : "Needed"
    }

    private var permissionSummary: String {
        appState.hasAccessibilityPermission
            ? "NumFn can remap keys on this Mac."
            : "Allow Accessibility access so NumFn can listen for the activation key."
    }

    private var permissionStatusColor: Color {
        appState.hasAccessibilityPermission ? .green : .orange
    }

    private var permissionSymbolName: String {
        appState.hasAccessibilityPermission ? "checkmark.shield" : "lock.shield"
    }
}

private struct PermissionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

private struct PermissionStatusPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        Text(value)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .accessibilityLabel(label)
            .accessibilityValue(value)
    }
}

private struct PermissionActionRow<Trailing: View>: View {
    let symbolName: String
    let tint: Color
    let title: String
    let detail: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontalLayout
            verticalLayout
        }
        .padding(.vertical, 2)
    }

    private var horizontalLayout: some View {
        HStack(alignment: .center, spacing: 12) {
            rowLabel

            Spacer(minLength: 16)

            trailing
                .fixedSize()
        }
    }

    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            rowLabel
            trailing
        }
    }

    private var rowLabel: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct PermissionNotice: View {
    let symbolName: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
                .frame(width: 18)
                .accessibilityHidden(true)

            Text(text)
                .foregroundStyle(tint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.callout)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(tint.opacity(0.18))
        )
        .accessibilityElement(children: .combine)
    }
}

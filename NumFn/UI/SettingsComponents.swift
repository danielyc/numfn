import SwiftUI

struct SettingsPane<Content: View>: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .center, spacing: 16) {
                SymbolBadge(symbolName: symbolName, tint: tint, size: 52)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.largeTitle.bold())
                    Text(subtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 18)

                MiniKeyPattern(tint: tint)
            }

            content
        }
        .frame(maxWidth: 800, alignment: .leading)
        .padding(32)
    }
}

struct SettingsGroup<Content: View>: View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
            Spacer()

            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(color)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}

struct PermissionStatusCard: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SettingsGroup("Accessibility") {
            StatusRow(
                title: "Permission",
                value: appState.hasAccessibilityPermission ? "Allowed" : "Needed",
                color: appState.hasAccessibilityPermission ? .green : .orange
            )

            Text("NumFn needs Accessibility access so it can listen for the activation key and remap keys locally.")
                .foregroundStyle(.secondary)
        }
    }
}

struct AppBackground: View {
    let tint: Color

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            LinearGradient(
                colors: [
                    tint.opacity(0.10),
                    Color(nsColor: .windowBackgroundColor).opacity(0.0)
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }
}

struct SymbolBadge: View {
    let symbolName: String
    let tint: Color
    let size: CGFloat

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tint.opacity(0.22))
            )
    }
}

struct MiniKeyPattern: View {
    let tint: Color

    private let columns = Array(repeating: GridItem(.fixed(16), spacing: 5), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(index.isMultiple(of: 3) ? tint.opacity(0.28) : Color.primary.opacity(0.08))
                    .frame(width: 16, height: 14)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
    }
}

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stepIndex = 0
    @State private var stepDirection = 1

    private let steps = OnboardingStep.allCases

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(steps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index <= stepIndex ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(height: index == stepIndex ? 6 : 5)
                        .opacity(index <= stepIndex ? 1 : 0.65)
                        .animation(stepAnimation, value: stepIndex)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, 28)

            Spacer(minLength: 24)

            stepContent
                .id(stepIndex)
                .transition(stepTransition)
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.horizontal, 42)

            Spacer(minLength: 24)

            HStack {
                Button("Back") {
                    moveToPreviousStep()
                }
                .disabled(stepIndex == 0)

                Spacer()

                Button(stepIndex == steps.count - 1 ? "Open Settings" : "Next") {
                    moveToNextStep()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(32)
        }
        .background(AppBackground(tint: currentStep.tint))
        .animation(stepAnimation, value: stepIndex)
    }

    private var currentStep: OnboardingStep {
        steps[stepIndex]
    }

    private var stepContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 16) {
                SymbolBadge(symbolName: currentStep.symbolName, tint: currentStep.tint, size: 54)

                Text(currentStep.title)
                    .font(.title.bold())
            }

            Text(currentStep.detail)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if currentStep == .welcome {
                CompactKeyboardPreview(tint: currentStep.tint)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(currentStep.points.indices, id: \.self) { index in
                    Label(currentStep.points[index], systemImage: "checkmark.circle")
                        .font(.body)
                        .opacity(reduceMotion ? 1 : 0.96)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            )
                        )
                        .animation(pointAnimation(for: index), value: stepIndex)
                }
            }

            if currentStep == .permission {
                PermissionStatusCard()
                HStack(spacing: 12) {
                    Button("Allow Accessibility") {
                        appState.requestAccessibilityPermission()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Open System Settings") {
                        appState.openAccessibilitySettings()
                    }
                }
            }
        }
    }

    private var stepAnimation: Animation? {
        reduceMotion ? .easeOut(duration: 0.01) : .spring(response: 0.34, dampingFraction: 0.88)
    }

    private var stepTransition: AnyTransition {
        guard !reduceMotion else {
            return .opacity
        }

        return .asymmetric(
            insertion: .opacity.combined(with: .move(edge: stepDirection >= 0 ? .trailing : .leading)),
            removal: .opacity.combined(with: .move(edge: stepDirection >= 0 ? .leading : .trailing))
        )
    }

    private func pointAnimation(for index: Int) -> Animation? {
        reduceMotion ? .easeOut(duration: 0.01) : .easeOut(duration: 0.20).delay(Double(index) * 0.035)
    }

    private func moveToPreviousStep() {
        stepDirection = -1
        withAnimation(stepAnimation) {
            stepIndex = max(stepIndex - 1, 0)
        }
    }

    private func moveToNextStep() {
        stepDirection = 1
        withAnimation(stepAnimation) {
            if stepIndex == steps.count - 1 {
                appState.completeOnboarding()
            } else {
                stepIndex += 1
            }
        }
    }
}

private enum OnboardingStep: CaseIterable, Equatable {
    case welcome
    case permission
    case basics
    case privacy

    var title: String {
        switch self {
        case .welcome:
            "Turn your keyboard into a numpad"
        case .permission:
            "Set up Accessibility access"
        case .basics:
            "Choose how NumFn turns on"
        case .privacy:
            "Local by design"
        }
    }

    var symbolName: String {
        switch self {
        case .welcome:
            "keyboard"
        case .permission:
            "accessibility"
        case .basics:
            "hand.tap"
        case .privacy:
            "lock.shield"
        }
    }

    var tint: Color {
        switch self {
        case .welcome:
            .teal
        case .permission:
            .orange
        case .basics:
            .blue
        case .privacy:
            .green
        }
    }

    var detail: String {
        switch self {
        case .welcome:
            "NumFn lives in your menu bar. Hold Fn to turn the left side of your keyboard into a numeric keypad."
        case .permission:
            "macOS needs your approval before NumFn can listen for the activation key and remap keys."
        case .basics:
            "Use the default Fn hold mode, switch to toggle mode, or choose another activation key in Settings."
        case .privacy:
            "NumFn has no analytics, network features, or keystroke logging."
        }
    }

    var points: [String] {
        switch self {
        case .welcome:
            [
                "Q W E become keypad 7 8 9.",
                "A S D become keypad 4 5 6.",
                "Z X C become keypad 1 2 3."
            ]
        case .permission:
            [
                "macOS handles the permission prompt.",
                "You can change it later in System Settings.",
                "After setup, NumFn lives in the menu bar."
            ]
        case .basics:
            [
                "Start with Numbers only or Numpad.",
                "Make a custom preset from any layout.",
                "Open Settings anytime from the menu bar."
            ]
        case .privacy:
            [
                "Your settings stay on this Mac.",
                "Keys are remapped only while the numpad layer is active.",
                "Nothing is sent off your Mac."
            ]
        }
    }
}

private struct CompactKeyboardPreview: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    let tint: Color

    private let rows = [
        ["Q", "W", "E", "R"],
        ["A", "S", "D", "F"],
        ["Z", "X", "C", "V"]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 7) {
                    ForEach(rows[rowIndex].indices, id: \.self) { columnIndex in
                        let key = rows[rowIndex][columnIndex]

                        Text(key)
                            .font(.caption.weight(.semibold))
                            .frame(width: 42, height: 32)
                            .background(keyBackground(for: key))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.primary.opacity(0.08))
                            )
                            .scaleEffect(isVisible || reduceMotion ? 1 : 0.92)
                            .opacity(isVisible || reduceMotion ? 1 : 0)
                            .offset(y: isVisible || reduceMotion ? 0 : 6)
                            .animation(keyAnimation(row: rowIndex, column: columnIndex), value: isVisible)
                    }
                }
                .padding(.leading, CGFloat(rowIndex) * 14)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(tint.opacity(0.20))
        )
        .accessibilityHidden(true)
        .onAppear {
            isVisible = true
        }
    }

    private func keyBackground(for key: String) -> LinearGradient {
        let highlighted = ["Q", "W", "E", "A", "S", "D", "Z", "X", "C"].contains(key)
        return LinearGradient(
            colors: highlighted
                ? [tint.opacity(0.24), tint.opacity(0.10)]
                : [Color.primary.opacity(0.06), Color.primary.opacity(0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func keyAnimation(row: Int, column: Int) -> Animation? {
        guard !reduceMotion else {
            return .easeOut(duration: 0.01)
        }

        let delay = Double(row * 4 + column) * 0.025
        return .spring(response: 0.28, dampingFraction: 0.82).delay(delay)
    }
}

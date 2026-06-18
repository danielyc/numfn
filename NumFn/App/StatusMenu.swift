import AppKit

@MainActor
final class StatusMenu: NSObject {
    private static let statusIconSize = NSSize(width: 18, height: 18)

    private let appState: AppState
    private let openSettingsWindow: () -> Void
    private let hideSettingsWindow: () -> Void
    private weak var statusItem: NSStatusItem?
    private var statusSummaryItem: NSMenuItem?
    private var toggleItem: NSMenuItem?
    private var permissionItem: NSMenuItem?

    init(
        appState: AppState,
        openSettingsWindow: @escaping () -> Void,
        hideSettingsWindow: @escaping () -> Void
    ) {
        self.appState = appState
        self.openSettingsWindow = openSettingsWindow
        self.hideSettingsWindow = hideSettingsWindow
    }

    func attach(to statusItem: NSStatusItem) {
        self.statusItem = statusItem
        statusItem.length = NSStatusItem.squareLength
        statusItem.button?.target = nil
        statusItem.button?.action = nil
        statusItem.button?.imagePosition = .imageOnly
        updateStatusItem()
    }

    func installMenu() {
        statusItem?.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let statusSummaryItem = NSMenuItem(
            title: "",
            action: nil,
            keyEquivalent: ""
        )
        statusSummaryItem.isEnabled = false
        menu.addItem(statusSummaryItem)
        self.statusSummaryItem = statusSummaryItem

        menu.addItem(.separator())

        let toggleItem = NSMenuItem(
            title: "",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        self.toggleItem = toggleItem

        let permissionItem = NSMenuItem(
            title: "",
            action: #selector(openAccessibilityPermissionHelp),
            keyEquivalent: ""
        )
        permissionItem.target = self
        menu.addItem(permissionItem)
        self.permissionItem = permissionItem

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Open Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit NumFn",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        menu.addItem(quitItem)

        menu.delegate = self
        refreshMenuItems()
        return menu
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        switch appState.runtimeStatus {
        case .disabled:
            appState.setEnabled(true)
        case .eventTapFailed:
            appState.retryKeyboardLayer()
        case .permissionMissing, .running:
            appState.setEnabled(false)
        }

        refreshMenuItems()
    }

    @objc private func openAccessibilityPermissionHelp() {
        appState.requestAccessibilityPermission()
        if !appState.hasAccessibilityPermission {
            appState.openAccessibilitySettings()
        }
        refreshMenuItems()
    }

    @objc private func openSettings() {
        openSettingsWindow()
    }

    func updateStatusItem() {
        guard let button = statusItem?.button else {
            return
        }

        button.title = ""
        button.attributedTitle = NSAttributedString(string: "")
        button.image = statusIconImage()
        button.imageScaling = .scaleNone
        button.toolTip = appState.runtimeStatus.menuBarTitle
        button.setAccessibilityLabel(appState.runtimeStatus.menuBarTitle)
    }

    private func refreshMenuItems() {
        updateStatusItem()
        statusSummaryItem?.title = "Status: \(appState.runtimeStatus.title)"
        toggleItem?.title = toggleTitle
        toggleItem?.state = appState.settings.isEnabled ? .on : .off
        permissionItem?.title = appState.hasAccessibilityPermission
            ? "Accessibility: Allowed"
            : "Set Up Accessibility..."
    }

    private var toggleTitle: String {
        switch appState.runtimeStatus {
        case .disabled:
            "Turn NumFn On"
        case .permissionMissing, .running:
            "Turn NumFn Off"
        case .eventTapFailed:
            "Try Again"
        }
    }

    private var statusItemColor: NSColor {
        switch appState.runtimeStatus {
        case .running:
            .systemGreen
        case .disabled:
            .systemRed
        case .permissionMissing, .eventTapFailed:
            .systemYellow
        }
    }

    private func statusIconImage() -> NSImage {
        let image = NSImage(size: Self.statusIconSize)

        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = NSRect(origin: .zero, size: Self.statusIconSize)
        let iconRect = rect.insetBy(dx: 1, dy: 1)
        statusItemColor.setFill()
        NSBezierPath(
            roundedRect: iconRect,
            xRadius: 4,
            yRadius: 4
        ).fill()

        if appState.isNumpadActive {
            NSColor.white.setFill()
            NSColor.white.setStroke()
            drawFunctionMark(in: iconRect.insetBy(dx: 2, dy: 1.5))
        } else {
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current?.compositingOperation = .clear
            drawFunctionMark(in: iconRect.insetBy(dx: 2, dy: 1.5))
            NSGraphicsContext.restoreGraphicsState()
        }

        image.isTemplate = false
        return image
    }

    private func drawFunctionMark(in targetRect: NSRect) {
        let sourceBounds = NSRect(x: 320, y: 155, width: 520, height: 725)
        let scale = min(targetRect.width / sourceBounds.width, targetRect.height / sourceBounds.height)
        let fittedSize = NSSize(
            width: sourceBounds.width * scale,
            height: sourceBounds.height * scale
        )
        let fittedRect = NSRect(
            x: targetRect.midX - fittedSize.width / 2,
            y: targetRect.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )

        func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            NSPoint(
                x: fittedRect.minX + (x - sourceBounds.minX) * scale,
                y: fittedRect.maxY - (y - sourceBounds.minY) * scale
            )
        }

        let mark = NSBezierPath()
        mark.move(to: point(370, 790))
        mark.curve(
            to: point(586, 545),
            controlPoint1: point(500, 835),
            controlPoint2: point(552, 690)
        )
        mark.curve(
            to: point(775, 210),
            controlPoint1: point(626, 375),
            controlPoint2: point(626, 198)
        )
        mark.lineWidth = max(3.1, 94 * scale)
        mark.lineCapStyle = .round
        mark.lineJoinStyle = .round
        mark.stroke()

        let crossbarLeft = point(438, 430)
        let crossbarRight = point(770, 508)
        let crossbarHeight = max(3, abs(crossbarLeft.y - crossbarRight.y))
        let crossbarRect = NSRect(
            x: crossbarLeft.x,
            y: (crossbarLeft.y + crossbarRight.y - crossbarHeight) / 2,
            width: crossbarRight.x - crossbarLeft.x,
            height: crossbarHeight
        )
        NSBezierPath(
            roundedRect: crossbarRect,
            xRadius: crossbarHeight / 2,
            yRadius: crossbarHeight / 2
        ).fill()
    }
}

extension StatusMenu: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        hideSettingsWindow()
        appState.refreshPermissions()
        refreshMenuItems()
    }
}

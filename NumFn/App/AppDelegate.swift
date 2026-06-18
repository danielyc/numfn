import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private lazy var statusMenu = StatusMenu(
        appState: appState,
        openSettingsWindow: { [weak self] in
            self?.openSettingsWindow()
        },
        hideSettingsWindow: { [weak self] in
            self?.hideSettingsWindow()
        }
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureApplicationIcon()
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        appState.onRuntimeStatusChange = { [weak self] in
            self?.statusMenu.updateStatusItem()
        }
        appState.onNumpadActiveChange = { [weak self] in
            self?.statusMenu.updateStatusItem()
        }
        appState.startKeyboardLayer()
        DispatchQueue.main.async { [weak self] in
            self?.openSettingsWindow()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.stopKeyboardLayer()
    }

    private func configureApplicationIcon() {
        guard let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
              let icon = NSImage(contentsOf: iconURL)
        else {
            return
        }

        NSApp.applicationIconImage = icon
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusMenu.attach(to: statusItem)
        statusMenu.installMenu()
        self.statusItem = statusItem
    }

    private func openSettingsWindow() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = SettingsView()
            .environmentObject(appState)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "NumFn Settings"
        window.contentView = NSHostingView(rootView: rootView)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        settingsWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideSettingsWindow() {
        settingsWindow?.orderOut(nil)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === settingsWindow {
            settingsWindow = nil
        }
    }
}

import CoreGraphics
import Foundation

final class KeyboardLayerController {
    enum ControllerError: LocalizedError {
        case eventTapUnavailable

        var errorDescription: String? {
            switch self {
            case .eventTapUnavailable:
                "macOS blocked NumFn from listening for key presses. Check Accessibility and Input Monitoring permissions."
            }
        }
    }

    private let mapper = NumpadMapper()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var settings: NumFnSettings = .default
    private var isToggleLayerActive = false
    private var wasActivationPressed = false
    private var isLayerActive = false
    var eventTapRecovered: (() -> Void)?
    var activationStateChanged: ((Bool) -> Void)?

    func start(settings: NumFnSettings) throws {
        stop()
        self.settings = settings

        let mask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: KeyboardLayerController.eventCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw ControllerError.eventTapUnavailable
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        self.eventTap = eventTap
        self.runLoopSource = source
    }

    func update(settings: NumFnSettings) {
        if self.settings.activationKey != settings.activationKey
            || self.settings.activationMode != settings.activationMode
            || self.settings.isEnabled != settings.isEnabled
        {
            isToggleLayerActive = false
            wasActivationPressed = false
            setLayerActive(false)
        }

        self.settings = settings
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isToggleLayerActive = false
        wasActivationPressed = false
        setLayerActive(false)
    }

    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard settings.isEnabled else {
            return Unmanaged.passUnretained(event)
        }

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                eventTapRecovered?()
            }
            return Unmanaged.passUnretained(event)
        }

        if type == .flagsChanged {
            updateActivationState(from: event)
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = KeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let isLayerActive = currentLayerActive(for: event)

        guard isLayerActive, let mappedKeyCode = mapper.mappedKeyCode(for: keyCode, layout: settings.layout) else {
            return Unmanaged.passUnretained(event)
        }

        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(mappedKeyCode))
        event.flags = event.flags.removingActivationFlags(for: settings.activationKey)
        return Unmanaged.passUnretained(event)
    }

    private func updateActivationState(from event: CGEvent) {
        let isPressed = isActivationPressed(event)

        if settings.activationMode == .toggle, isPressed, !wasActivationPressed {
            isToggleLayerActive.toggle()
        }

        wasActivationPressed = isPressed
        setLayerActive(currentLayerActive(for: event))
    }

    private func isActivationPressed(_ event: CGEvent) -> Bool {
        switch settings.activationKey {
        case .function:
            event.flags.contains(.maskSecondaryFn)
        case .option:
            event.flags.contains(.maskAlternate)
        case .command:
            event.flags.contains(.maskCommand)
        case .control:
            event.flags.contains(.maskControl)
        }
    }

    private func currentLayerActive(for event: CGEvent) -> Bool {
        settings.activationMode == .hold ? isActivationPressed(event) : isToggleLayerActive
    }

    private func setLayerActive(_ isActive: Bool) {
        guard isLayerActive != isActive else {
            return
        }

        isLayerActive = isActive
        activationStateChanged?(isActive)
    }

    private static let eventCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let controller = Unmanaged<KeyboardLayerController>
            .fromOpaque(userInfo)
            .takeUnretainedValue()

        return controller.handle(proxy: proxy, type: type, event: event)
    }
}

private extension CGEventFlags {
    func removingActivationFlags(for activationKey: ActivationKey) -> CGEventFlags {
        var flags = self

        switch activationKey {
        case .function:
            flags.remove(.maskSecondaryFn)
        case .option:
            flags.remove(.maskAlternate)
        case .command:
            flags.remove(.maskCommand)
        case .control:
            flags.remove(.maskControl)
        }

        return flags
    }
}

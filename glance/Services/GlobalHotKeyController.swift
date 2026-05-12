import Carbon
import Foundation

@MainActor
protocol GlobalHotKeyControllerDelegate: AnyObject {
    func globalHotKeyControllerDidTrigger(_ controller: GlobalHotKeyController)
}

@MainActor
final class GlobalHotKeyController {
    weak var delegate: GlobalHotKeyControllerDelegate?

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID = EventHotKeyID(
        signature: GlobalHotKeyController.fourCharCode("glnc"),
        id: 1
    )

    func register(keyCode: UInt32, modifiers: UInt32) -> Bool {
        unregister()
        installEventHandlerIfNeeded()

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        return status == noErr
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else {
            return
        }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard
                    let userData,
                    let event
                else {
                    return noErr
                }

                let controller = Unmanaged<GlobalHotKeyController>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                return controller.handleHotKeyEvent(event)
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    private func handleHotKeyEvent(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard
            status == noErr,
            hotKeyID.signature == self.hotKeyID.signature,
            hotKeyID.id == self.hotKeyID.id
        else {
            return status
        }

        delegate?.globalHotKeyControllerDidTrigger(self)
        return noErr
    }

    private static func fourCharCode(_ value: String) -> OSType {
        value.utf8.prefix(4).reduce(0) { partial, next in
            (partial << 8) + OSType(next)
        }
    }
}

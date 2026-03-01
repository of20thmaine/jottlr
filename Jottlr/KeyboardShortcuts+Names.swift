import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let quickCapture = Self("quickCapture", default: .init(.j, modifiers: [.command, .shift]))
}

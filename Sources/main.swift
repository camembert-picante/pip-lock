import AppKit
import Carbon.HIToolbox

private let floatingLayer = Int(CGWindowLevelForKey(.floatingWindow))
private let edgeMargin: CGFloat = 10

final class Shield: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = NSWindow.Level(rawValue: floatingLayer + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        // A clear window lets clicks through unless this is set to false.
        ignoresMouseEvents = false
        hidesOnDeactivate = false
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class App: NSObject, NSApplicationDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let toggleItem = NSMenuItem(title: "Lock Picture-in-Picture", action: #selector(toggle), keyEquivalent: "l")
    private var shields: [CGWindowID: Shield] = [:]
    private var timer: Timer?
    private var locked = false { didSet { refresh() } }

    func applicationDidFinishLaunching(_ note: Notification) {
        toggleItem.target = self
        toggleItem.keyEquivalentModifierMask = [.control, .option]
        let menu = NSMenu()
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit PiP Lock", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        registerHotKey()
        refresh()
    }

    @objc func toggle() { locked.toggle() }

    private func refresh() {
        let symbol = locked ? "lock.fill" : "lock.open"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: locked ? "Locked" : "Unlocked")
        image?.isTemplate = true
        item.button?.image = image
        toggleItem.title = locked ? "Unlock Picture-in-Picture" : "Lock Picture-in-Picture"
        toggleItem.state = locked ? .on : .off

        timer?.invalidate()
        timer = nil
        if locked {
            let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in self?.sync() }
            RunLoop.main.add(t, forMode: .common)
            timer = t
            sync()
        } else {
            shields.values.forEach { $0.orderOut(nil) }
            shields.removeAll()
        }
    }

    private func pipWindows() -> [CGWindowID: CGRect] {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return [:] }
        var found: [CGWindowID: CGRect] = [:]
        for w in list {
            guard (w[kCGWindowLayer as String] as? Int) == floatingLayer,
                  let pid = w[kCGWindowOwnerPID as String] as? pid_t,
                  let bundle = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier,
                  bundle.hasPrefix("org.mozilla."),
                  let id = w[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = w[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict),
                  bounds.width >= 80, bounds.height >= 45 else { continue }
            found[id] = bounds
        }
        return found
    }

    private func sync() {
        let windows = pipWindows()
        for (id, shield) in shields where windows[id] == nil {
            shield.orderOut(nil)
            shields[id] = nil
        }
        guard let primaryHeight = NSScreen.screens.first?.frame.height else { return }
        for (id, r) in windows {
            // CoreGraphics measures from the top-left, AppKit from the bottom-left of the main screen.
            // The margin also blocks the resize zone just outside the window's edge.
            let frame = NSRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
                .insetBy(dx: -edgeMargin, dy: -edgeMargin)
            let shield = shields[id] ?? Shield()
            shields[id] = shield
            if shield.frame != frame { shield.setFrame(frame, display: false) }
            if !shield.isVisible { shield.orderFrontRegardless() }
        }
    }

    private func registerHotKey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, ctx in
            let app = Unmanaged<App>.fromOpaque(ctx!).takeUnretainedValue()
            DispatchQueue.main.async { app.toggle() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
        var ref: EventHotKeyRef?
        RegisterEventHotKey(UInt32(kVK_ANSI_L), UInt32(controlKey | optionKey),
                            EventHotKeyID(signature: OSType(0x5050_4C4B), id: 1),
                            GetApplicationEventTarget(), 0, &ref)
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

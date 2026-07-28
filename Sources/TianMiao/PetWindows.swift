import Cocoa

final class TianMiaoWindow: NSWindow {
    override var canBecomeKey: Bool { true }

    init(contentRect: NSRect) {
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .fullSizeContentView],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        isMovable = false
        ignoresMouseEvents = false
    }
}

final class BubbleWindow: NSWindow {
    private let label = NSTextField(labelWithString: "")
    private let bubbleLayer = CAShapeLayer()
    private let font = NSFont.systemFont(ofSize: 10.5, weight: .medium)
    private var hideWorkItem: DispatchWorkItem?

    init() {
        let initialSize = NSSize(width: 104, height: 42)
        super.init(contentRect: NSRect(origin: .zero, size: initialSize),
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        ignoresMouseEvents = true

        let content = NSView(frame: NSRect(origin: .zero, size: initialSize))
        content.wantsLayer = true
        bubbleLayer.fillColor = NSColor(calibratedWhite: 1, alpha: 0.94).cgColor
        bubbleLayer.strokeColor = NSColor(calibratedWhite: 0.68, alpha: 0.9).cgColor
        bubbleLayer.lineWidth = 0.8
        content.layer?.addSublayer(bubbleLayer)

        label.font = font
        label.textColor = NSColor(calibratedWhite: 0.18, alpha: 1)
        label.alignment = .center
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 3
        content.addSubview(label)
        self.contentView = content
        layoutBubble(size: initialSize)
    }

    private func fittedSize(for message: String) -> NSSize {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let measured = (message as NSString).boundingRect(
            with: NSSize(width: 116, height: 120),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )
        return NSSize(width: min(136, max(72, ceil(measured.width) + 20)),
                      height: min(62, max(38, ceil(measured.height) + 18)))
    }

    private func layoutBubble(size: NSSize) {
        guard let contentView else { return }
        contentView.frame = NSRect(origin: .zero, size: size)
        bubbleLayer.frame = contentView.bounds
        let body = CGRect(x: 1, y: 7, width: size.width - 2, height: size.height - 8)
        let path = CGMutablePath()
        path.addRoundedRect(in: body, cornerWidth: 10, cornerHeight: 10)
        path.move(to: CGPoint(x: size.width * 0.43, y: 8))
        path.addLine(to: CGPoint(x: size.width * 0.5, y: 1))
        path.addLine(to: CGPoint(x: size.width * 0.57, y: 8))
        path.closeSubpath()
        bubbleLayer.path = path
        label.frame = NSRect(x: 10, y: 10, width: size.width - 20, height: size.height - 15)
    }

    func show(_ message: String, near frame: NSRect, walking: Bool, for seconds: TimeInterval = 3.2) {
        hideWorkItem?.cancel()
        label.stringValue = message
        let size = fittedSize(for: message)
        setContentSize(size)
        layoutBubble(size: size)
        orderFront(nil)
        reposition(near: frame, walking: walking)

        let workItem = DispatchWorkItem { [weak self] in self?.orderOut(nil) }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: workItem)
    }

    func reposition(near frame: NSRect, walking: Bool) {
        guard isVisible else { return }
        let center = NSPoint(x: frame.midX, y: frame.midY)
        let screen = NSScreen.screens.first(where: { $0.frame.contains(center) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let visibleTop = frame.minY + frame.height * (walking ? 0.74 : 0.93)
        let rawOrigin = NSPoint(x: frame.midX - self.frame.width / 2, y: visibleTop + 2)
        let origin = NSPoint(
            x: min(max(rawOrigin.x, screen.minX + 6), screen.maxX - self.frame.width - 6),
            y: min(max(rawOrigin.y, screen.minY + 6), screen.maxY - self.frame.height - 6)
        )
        setFrameOrigin(origin)
    }
}


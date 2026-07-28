import Cocoa
import QuartzCore

final class CatView: NSView {
    private let shadowLayer = CALayer()
    private let poseLayer = CALayer()
    private let rigLayer = CALayer()
    private let sittingCoreLayer = CALayer()
    private let tailLayer = CALayer()
    private let bodyLayer = CALayer()
    private let haunchLayer = CALayer()
    private let leftPawLayer = CALayer()
    private let rightPawLayer = CALayer()
    private let headLayer = CALayer()
    private let leftBlinkLayer = CALayer()
    private let rightBlinkLayer = CALayer()
    private let leftBlinkLine = CAShapeLayer()
    private let rightBlinkLine = CAShapeLayer()
    private let walkCoreLayer = CALayer()
    private let walkTailLayer = CALayer()
    private let walkRearLegLayer = CALayer()
    private let walkHindLegLayer = CALayer()
    private let walkBodyLayer = CALayer()
    private let walkFrontDownLegLayer = CALayer()
    private let walkFrontLegLayer = CALayer()
    private let walkHeadLayer = CALayer()
    private var currentMood: PetMood = .idle
    private var petState: PetState = .idle
    private var currentAction: PetAction?
    private var poseFrames: [PetMood: [CGImage]] = [:]
    private var walkPoseFrames: [CGImage] = []
    private var settleTimer: Timer?
    private var isWalking = false
    private var wasDragged = false
    private var dragStartPoint: NSPoint = .zero
    private var dragStartWindowOrigin: NSPoint = .zero
    private weak var controller: PetController?

    private var sittingLayers: [CALayer] {
        [tailLayer, haunchLayer, bodyLayer, leftPawLayer, rightPawLayer, headLayer]
    }

    private var walkingLayers: [CALayer] {
        [walkTailLayer, walkRearLegLayer, walkHindLegLayer, walkFrontLegLayer,
         walkBodyLayer, walkFrontDownLegLayer, walkHeadLayer]
    }

    private var partLayers: [CALayer] {
        sittingLayers + walkingLayers
    }

    var isPerformingAction: Bool {
        currentMood != .idle
    }

    var isWalkingPose: Bool {
        isWalking
    }

    var isSleeping: Bool {
        currentMood == .sleep
    }

    init(frame: NSRect, controller: PetController) {
        self.controller = controller
        super.init(frame: frame)
        wantsLayer = true
        layer?.masksToBounds = false
        setupRenderLayers()
        loadRigParts()
        loadPoseFrames()
        showMood(.idle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        rigLayer.frame = bounds.insetBy(dx: bounds.width * 0.08, dy: bounds.height * 0.05)
        poseLayer.frame = bounds.insetBy(dx: bounds.width * 0.015, dy: bounds.height * 0.015)
        sittingCoreLayer.frame = rigLayer.bounds
        walkCoreLayer.frame = rigLayer.bounds
        configurePart(tailLayer, anchor: CGPoint(x: 0.43, y: 0.23))
        configurePart(haunchLayer, anchor: CGPoint(x: 0.56, y: 0.19))
        configurePart(bodyLayer, anchor: CGPoint(x: 0.56, y: 0.31))
        configurePart(leftPawLayer, anchor: CGPoint(x: 0.48, y: 0.31))
        configurePart(rightPawLayer, anchor: CGPoint(x: 0.69, y: 0.31))
        configurePart(headLayer, anchor: CGPoint(x: 0.52, y: 0.39))
        configureBlinkLayer(leftBlinkLayer, line: leftBlinkLine,
                            sourceRect: CGRect(x: 128, y: 151, width: 62, height: 64))
        configureBlinkLayer(rightBlinkLayer, line: rightBlinkLine,
                            sourceRect: CGRect(x: 202, y: 105, width: 68, height: 68))
        configurePart(walkTailLayer, anchor: CGPoint(x: 0.23, y: 0.37))
        configurePart(walkRearLegLayer, anchor: CGPoint(x: 0.29, y: 0.30))
        configurePart(walkHindLegLayer, anchor: CGPoint(x: 0.45, y: 0.30))
        configurePart(walkBodyLayer, anchor: CGPoint(x: 0.43, y: 0.31))
        configurePart(walkFrontDownLegLayer, anchor: CGPoint(x: 0.58, y: 0.33))
        configurePart(walkFrontLegLayer, anchor: CGPoint(x: 0.62, y: 0.33))
        configurePart(walkHeadLayer, anchor: CGPoint(x: 0.56, y: 0.34))
        shadowLayer.frame = NSRect(x: bounds.width * 0.24,
                                   y: bounds.height * 0.055,
                                   width: bounds.width * 0.52,
                                   height: max(8, bounds.height * 0.075))
        shadowLayer.cornerRadius = shadowLayer.frame.height / 2
    }

    private func setupRenderLayers() {
        guard let rootLayer = layer else { return }
        rootLayer.sublayerTransform = CATransform3DIdentity
        rootLayer.sublayerTransform.m34 = -1.0 / 700.0

        shadowLayer.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        shadowLayer.opacity = 0.7
        shadowLayer.masksToBounds = true
        rootLayer.addSublayer(shadowLayer)

        poseLayer.contentsGravity = .resizeAspect
        poseLayer.minificationFilter = .trilinear
        poseLayer.magnificationFilter = .linear
        poseLayer.masksToBounds = false
        rootLayer.addSublayer(poseLayer)

        rigLayer.masksToBounds = false
        rigLayer.opacity = 0
        rootLayer.addSublayer(rigLayer)
        sittingCoreLayer.masksToBounds = false
        walkCoreLayer.masksToBounds = false

        for part in [tailLayer, haunchLayer] {
            part.contentsGravity = .resizeAspect
            part.minificationFilter = .linear
            part.magnificationFilter = .linear
            part.masksToBounds = false
            rigLayer.addSublayer(part)
        }
        rigLayer.addSublayer(sittingCoreLayer)
        for part in [bodyLayer, leftPawLayer, rightPawLayer, headLayer] {
            part.contentsGravity = .resizeAspect
            part.minificationFilter = .linear
            part.magnificationFilter = .linear
            part.masksToBounds = false
            sittingCoreLayer.addSublayer(part)
        }
        for part in [walkTailLayer, walkRearLegLayer, walkHindLegLayer, walkFrontLegLayer] {
            part.contentsGravity = .resizeAspect
            part.minificationFilter = .linear
            part.magnificationFilter = .linear
            part.masksToBounds = false
            rigLayer.addSublayer(part)
        }
        rigLayer.addSublayer(walkCoreLayer)
        for part in [walkBodyLayer, walkFrontDownLegLayer, walkHeadLayer] {
            part.contentsGravity = .resizeAspect
            part.minificationFilter = .linear
            part.magnificationFilter = .linear
            part.masksToBounds = false
            walkCoreLayer.addSublayer(part)
        }
        setupBlinkLayer(leftBlinkLayer, line: leftBlinkLine)
        setupBlinkLayer(rightBlinkLayer, line: rightBlinkLine)
        needsLayout = true
    }

    private func setupBlinkLayer(_ eyelid: CALayer, line: CAShapeLayer) {
        eyelid.backgroundColor = NSColor(calibratedWhite: 0.92, alpha: 1).cgColor
        eyelid.borderColor = NSColor(calibratedWhite: 0.14, alpha: 1).cgColor
        eyelid.borderWidth = 1.1
        eyelid.opacity = 0
        line.fillColor = NSColor.clear.cgColor
        line.strokeColor = NSColor(calibratedWhite: 0.14, alpha: 1).cgColor
        line.lineCap = .round
        eyelid.addSublayer(line)
        headLayer.addSublayer(eyelid)
    }

    private func configureBlinkLayer(_ eyelid: CALayer, line: CAShapeLayer, sourceRect: CGRect) {
        let sourceSize = CGSize(width: 360, height: 392)
        let scale = min(headLayer.bounds.width / sourceSize.width,
                        headLayer.bounds.height / sourceSize.height)
        let offsetX = (headLayer.bounds.width - sourceSize.width * scale) / 2
        let offsetY = (headLayer.bounds.height - sourceSize.height * scale) / 2
        eyelid.frame = CGRect(x: offsetX + sourceRect.minX * scale,
                              y: offsetY + (sourceSize.height - sourceRect.maxY) * scale,
                              width: sourceRect.width * scale,
                              height: sourceRect.height * scale)
        eyelid.cornerRadius = eyelid.bounds.height / 2
        line.frame = eyelid.bounds
        line.lineWidth = max(0.8, scale * 2.5)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: eyelid.bounds.width * 0.16, y: eyelid.bounds.midY * 0.98))
        path.addQuadCurve(to: CGPoint(x: eyelid.bounds.width * 0.84, y: eyelid.bounds.midY * 0.98),
                          control: CGPoint(x: eyelid.bounds.midX, y: eyelid.bounds.midY * 0.72))
        line.path = path
    }

    private func configurePart(_ part: CALayer, anchor: CGPoint) {
        let containerBounds = part.superlayer?.bounds ?? rigLayer.bounds
        part.bounds = containerBounds
        part.anchorPoint = anchor
        part.position = CGPoint(x: containerBounds.width * anchor.x,
                                y: containerBounds.height * anchor.y)
    }

    private func loadRigParts() {
        let resources: [(CALayer, String)] = [
            (tailLayer, "rig_tail"),
            (bodyLayer, "rig_body"),
            (haunchLayer, "rig_haunches"),
            (leftPawLayer, "rig_paw_left"),
            (rightPawLayer, "rig_paw_right"),
            (headLayer, "rig_head"),
            (walkTailLayer, "walk_tail"),
            (walkRearLegLayer, "walk_rear_leg"),
            (walkHindLegLayer, "walk_hind_leg"),
            (walkBodyLayer, "walk_body"),
            (walkFrontDownLegLayer, "walk_front_down_leg"),
            (walkFrontLegLayer, "walk_front_leg"),
            (walkHeadLayer, "walk_head")
        ]
        for (part, name) in resources {
            guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
                  let image = NSImage(contentsOf: url) else { continue }
            part.contents = image
        }
        setWalkingPose(false)
    }

    private func loadPoseFrames() {
        let counts: [PetMood: Int] = [
            .idle: 2, .blink: 2, .react: 2, .groom: 4,
            .scratch: 4, .jump: 4, .sleep: 2, .roll: 5
        ]
        for (mood, count) in counts {
            let prefix = (mood == .blink || mood == .react) ? "idle" : mood.rawValue
            poseFrames[mood] = loadImages(prefix: prefix, count: count)
        }
        walkPoseFrames = loadImages(prefix: "walk", count: 4)
    }

    private func loadImages(prefix: String, count: Int) -> [CGImage] {
        (0..<count).compactMap { index in
            guard let url = Bundle.main.url(
                forResource: String(format: "%@_%02d", prefix, index),
                withExtension: "png",
                subdirectory: "Poses"
            ),
            let image = NSImage(contentsOf: url) else {
                return nil
            }
            var rect = NSRect(origin: .zero, size: image.size)
            return image.cgImage(forProposedRect: &rect, context: nil, hints: nil)
        }
    }

    private func showPoseFrames(_ frames: [CGImage],
                                duration: TimeInterval,
                                repeatForever: Bool = false) {
        guard !frames.isEmpty else { return }
        poseLayer.removeAnimation(forKey: "poseTimeline")
        if let progressText = ProcessInfo.processInfo.environment["TIANMIAO_PREVIEW_PROGRESS"],
           let progress = Double(progressText) {
            let clamped = min(1, max(0, progress))
            let index = min(frames.count - 1, Int(Double(frames.count) * clamped))
            poseLayer.contents = frames[index]
            return
        }
        poseLayer.contents = frames.last
        guard frames.count > 1 else { return }
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = frames
        animation.duration = duration
        animation.calculationMode = .discrete
        animation.repeatCount = repeatForever ? .infinity : 0
        animation.isRemovedOnCompletion = !repeatForever
        poseLayer.add(animation, forKey: "poseTimeline")
    }

    private func showPose(_ mood: PetMood,
                          duration: TimeInterval,
                          repeatForever: Bool = false) {
        guard let frames = poseFrames[mood] else { return }
        showPoseFrames(frames, duration: duration, repeatForever: repeatForever)
    }

    private func setWalkingPose(_ walking: Bool, animated: Bool = false) {
        let sittingOpacity: Float = walking ? 0 : 1
        let walkingOpacity: Float = walking ? 1 : 0
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        sittingLayers.forEach { $0.opacity = sittingOpacity }
        walkingLayers.forEach { $0.opacity = walkingOpacity }
        CATransaction.commit()

        guard animated else { return }
        for layer in sittingLayers {
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = walking ? 1 : 0
            fade.toValue = sittingOpacity
            fade.duration = walking ? 0.22 : 0.18
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(fade, forKey: "poseFade")
        }
        for layer in walkingLayers {
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = walking ? 0 : 1
            fade.toValue = walkingOpacity
            fade.duration = walking ? 0.22 : 0.18
            fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(fade, forKey: "poseFade")
        }
    }

    private func showMood(_ mood: PetMood) {
        currentMood = mood
        petState = mood == .sleep ? .sleeping : .idle
        currentAction = nil
        clearActionMotion()
        if mood == .idle {
            startIdleMotion()
            showPose(.idle, duration: 2.8, repeatForever: true)
        }
    }

    func play(_ mood: PetMood, frameDuration: TimeInterval = 0.16, loops: Int = 1) {
        if mood == .sleep {
            startSleeping()
            return
        }
        settleTimer?.invalidate()
        let wasWalking = isWalking
        currentMood = mood
        currentAction = PetAction(rawValue: mood.rawValue)
        petState = .idle
        isWalking = false
        let actionFrames: [PetMood: Int] = [
            .blink: 4, .react: 5, .groom: 7, .scratch: 12, .jump: 7, .roll: 10
        ]
        let duration = frameDuration * Double(actionFrames[mood] ?? 5) * Double(max(1, loops))
        applyActionMotion(for: mood, duration: duration)
        showPose(mood, duration: duration)
        if wasWalking {
            setWalkingPose(false, animated: true)
        }
        settleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.showMood(.idle)
        }
    }

    func playIfIdle(_ mood: PetMood, frameDuration: TimeInterval = 0.16, loops: Int = 1) {
        guard currentMood == .idle, !isWalking else { return }
        play(mood, frameDuration: frameDuration, loops: loops)
    }

    func startSleeping(for duration: TimeInterval? = nil) {
        guard currentMood == .idle || currentMood == .blink else { return }
        settleTimer?.invalidate()
        isWalking = false
        currentMood = .sleep
        petState = .sleeping
        currentAction = nil
        setWalkingPose(false, animated: true)
        applyActionMotion(for: .sleep, duration: duration ?? 3.2)
        showPose(.sleep, duration: 3.2, repeatForever: duration == nil)
        if let duration {
            settleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.wakeUp()
            }
        }
    }

    func wakeUp() {
        guard currentMood == .sleep else { return }
        settleTimer?.invalidate()
        showMood(.idle)
    }

    private func clearActionMotion() {
        rigLayer.removeAllAnimations()
        sittingCoreLayer.removeAllAnimations()
        walkCoreLayer.removeAllAnimations()
        shadowLayer.removeAllAnimations()
        poseLayer.removeAnimation(forKey: "poseTimeline")
        partLayers.forEach { $0.removeAllAnimations() }
        leftBlinkLayer.removeAllAnimations()
        rightBlinkLayer.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rigLayer.transform = CATransform3DIdentity
        sittingCoreLayer.transform = CATransform3DIdentity
        walkCoreLayer.transform = CATransform3DIdentity
        partLayers.forEach { $0.transform = CATransform3DIdentity }
        headLayer.transform = CATransform3DIdentity
        walkHeadLayer.transform = CATransform3DIdentity
        leftBlinkLayer.opacity = 0
        rightBlinkLayer.opacity = 0
        shadowLayer.opacity = 0.7
        CATransaction.commit()
        setWalkingPose(false)
    }

    private func keyframe(_ keyPath: String,
                          values: [CGFloat],
                          duration: TimeInterval,
                          keyTimes: [NSNumber]? = nil,
                          additive: Bool = true,
                          repeatCount: Float = 0) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.values = values
        animation.keyTimes = keyTimes
        animation.duration = duration
        animation.isAdditive = additive
        animation.calculationMode = .cubic
        animation.repeatCount = repeatCount
        animation.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeInEaseOut),
                                          count: max(1, values.count - 1))
        return animation
    }

    private func applyActionMotion(for mood: PetMood, duration: TimeInterval) {
        clearActionMotion()
        let total = max(0.18, duration)
        switch mood {
        case .idle:
            break
        case .blink:
            let times: [NSNumber] = [0, 0.32, 0.48, 0.64, 1]
            let blinkTimes: [NSNumber] = [0, 0.26, 0.38, 0.56, 0.7, 1]
            add(leftBlinkLayer, "opacity", [0, 0, 1, 1, 0, 0], total, blinkTimes,
                additive: false, key: "leftBlink")
            add(rightBlinkLayer, "opacity", [0, 0, 1, 1, 0, 0], total, blinkTimes,
                additive: false, key: "rightBlink")
            add(headLayer, "transform.translation.y", [0, 0, -0.8, 0, 0], total, times)
            add(headLayer, "transform.rotation.z", [0, 0.008, 0.014, 0.008, 0], total, times)
        case .react:
            break
        case .groom:
            let pawLift = max(11, bounds.height * 0.12)
            let times: [NSNumber] = [0, 0.2, 0.38, 0.56, 0.74, 0.9, 1]
            add(leftPawLayer, "transform.translation.y", [0, pawLift * 0.72, pawLift, pawLift * 0.78, pawLift, pawLift * 0.65, 0], total, times)
            add(leftPawLayer, "transform.translation.x", [0, 1, -2, 1, -2, 0, 0], total, times)
            add(leftPawLayer, "transform.rotation.z", [0, -0.18, -0.25, -0.16, -0.25, -0.12, 0], total, times)
            add(headLayer, "transform.rotation.z", [0, 0.035, 0.065, 0.035, 0.065, 0.025, 0], total, times)
            add(headLayer, "transform.translation.x", [0, -1, -2, -1, -2, -1, 0], total, times)
            add(rightPawLayer, "transform.scale.y", [1, 0.985, 0.98, 0.985, 0.98, 0.99, 1], total, times, additive: false)
            add(sittingCoreLayer, "transform.translation.x", [0, 1, 1.5, 1, 1.5, 0.5, 0], total, times)
            add(tailLayer, "transform.rotation.z", [0, 0.05, -0.035, 0.05, -0.035, 0.025, 0], total, times)
        case .scratch:
            let times: [NSNumber] = [0, 0.1, 0.2, 0.32, 0.44, 0.56, 0.68, 0.8, 0.9, 1]
            add(rigLayer, "transform.translation.y", [0, -1, -1.5, -1.5, -1.5, -1.5, -1.5, -1, -0.5, 0], total, times)
            add(bodyLayer, "transform.scale.y", [1, 0.985, 0.98, 0.985, 0.98, 0.985, 0.98, 0.987, 0.995, 1],
                total, times, additive: false)
            add(headLayer, "transform.translation.y", [0, -1, -2, -2, -2, -2, -2, -1, -0.5, 0], total, times)
            add(headLayer, "transform.rotation.z", [0, -0.015, -0.025, -0.02, -0.025, -0.02, -0.025, -0.015, 0, 0], total, times)
            add(leftPawLayer, "transform.translation.x", [0, -1, 0, -1, 0, -1, 0, -1, 0, 0], total, times)
            add(leftPawLayer, "transform.scale.y", [1, 0.985, 0.98, 0.985, 0.98, 0.985, 0.98, 0.99, 1, 1], total, times, additive: false)
            add(rightPawLayer, "transform.translation.y", [0, 3, -1, 4, -1, 4, -1, 3, 1, 0], total, times)
            add(rightPawLayer, "transform.translation.x", [0, -3, 3, -4, 3, -4, 3, -3, 1, 0], total, times)
            add(rightPawLayer, "transform.rotation.z", [0, -0.08, 0.07, -0.1, 0.08, -0.1, 0.08, -0.07, 0.02, 0], total, times)
            add(haunchLayer, "transform.translation.x", [0, -0.5, -1, -1, -1, -1, -1, -0.5, 0, 0], total, times)
            add(tailLayer, "transform.rotation.z", [0, -0.035, 0.05, -0.05, 0.055, -0.05, 0.05, -0.03, 0.01, 0], total, times)
            addShadowPulse(scale: [1, 1.02, 1.035, 1.02, 1.035, 1.02, 1.035, 1.02, 1.01, 1],
                           opacity: [0.68, 0.7, 0.72, 0.7, 0.72, 0.7, 0.72, 0.7, 0.69, 0.68],
                           duration: total,
                           keyTimes: times)
        case .jump:
            let lift = max(13, bounds.height * 0.18)
            let times: [NSNumber] = [0, 0.16, 0.3, 0.5, 0.68, 0.84, 1]
            add(rigLayer, "transform.translation.y",
                [0, -3, lift * 0.78, lift, lift * 0.72, -2, 0], total, times)
            add(bodyLayer, "transform.scale.y",
                [1, 0.94, 1.05, 1.02, 1.04, 0.96, 1], total, times, additive: false)
            add(haunchLayer, "transform.translation.y",
                [0, -2, 2, 3, 2, -1, 0], total, times)
            add(leftPawLayer, "transform.translation.y",
                [0, -2, 7, 10, 7, -1, 0], total, times)
            add(rightPawLayer, "transform.translation.y",
                [0, -2, 8, 11, 8, -1, 0], total, times)
            add(leftPawLayer, "transform.rotation.z",
                [0, 0.03, -0.13, -0.17, -0.12, 0.03, 0], total, times)
            add(rightPawLayer, "transform.rotation.z",
                [0, -0.03, 0.13, 0.17, 0.12, -0.03, 0], total, times)
            add(headLayer, "transform.translation.y",
                [0, -1, 2, 4, 2, -1, 0], total, times)
            add(tailLayer, "transform.rotation.z",
                [0, -0.08, 0.12, 0.17, 0.1, -0.04, 0], total, times)
            addShadowPulse(scale: [1, 1.08, 0.72, 0.64, 0.74, 1.08, 1],
                           opacity: [0.68, 0.74, 0.42, 0.32, 0.45, 0.76, 0.68],
                           duration: total,
                           keyTimes: times)
        case .sleep:
            let forever = Float.infinity
            add(leftBlinkLayer, "opacity", [1, 1], 3.2,
                additive: false, repeatCount: forever, key: "sleepLeftEye")
            add(rightBlinkLayer, "opacity", [1, 1], 3.2,
                additive: false, repeatCount: forever, key: "sleepRightEye")
            add(sittingCoreLayer, "transform.translation.y", [0, -1.2, 0], 3.2,
                repeatCount: forever, key: "sleepWeight")
            add(bodyLayer, "transform.scale.y", [0.975, 0.995, 0.975], 3.2,
                additive: false, repeatCount: forever, key: "sleepBreath")
            add(headLayer, "transform.translation.y", [-1, -2.2, -1], 3.2,
                repeatCount: forever, key: "sleepHead")
            add(headLayer, "transform.rotation.z", [0.035, 0.05, 0.035], 3.2,
                repeatCount: forever, key: "sleepHeadTilt")
            add(leftPawLayer, "transform.translation.x", [0, 1.2, 0], 3.2,
                repeatCount: forever, key: "sleepLeftPaw")
            add(rightPawLayer, "transform.translation.x", [0, -1.2, 0], 3.2,
                repeatCount: forever, key: "sleepRightPaw")
            add(tailLayer, "transform.rotation.z", [-0.06, 0.025, -0.06], 4.2,
                repeatCount: forever, key: "sleepTail")
            addShadowPulse(scale: [1.02, 0.98, 1.02],
                           opacity: [0.66, 0.61, 0.66],
                           duration: 3.2,
                           repeatForever: true)
        case .roll:
            let times: [NSNumber] = [0, 0.12, 0.25, 0.4, 0.56, 0.72, 0.86, 1]
            add(sittingCoreLayer, "transform.translation.x",
                [0, -2, -4, -5, -4, -2, 0.5, 0], total, times)
            add(sittingCoreLayer, "transform.translation.y",
                [0, -1, 0.5, 2, 1.5, 0.5, -0.5, 0], total, times)
            add(bodyLayer, "transform.rotation.z",
                [0, -0.035, -0.09, -0.14, -0.1, -0.04, 0.015, 0], total, times)
            add(haunchLayer, "transform.rotation.z",
                [0, -0.03, -0.075, -0.12, -0.08, -0.03, 0.012, 0], total, times)
            add(headLayer, "transform.rotation.z",
                [0, -0.025, -0.07, -0.11, -0.075, -0.025, 0.012, 0], total, times)
            add(headLayer, "transform.translation.x",
                [0, -0.5, -1.5, -2, -1.5, -0.5, 0, 0], total, times)
            add(leftPawLayer, "transform.translation.y",
                [0, 1, 3.5, 5, 4, 2, 0.5, 0], total, times)
            add(rightPawLayer, "transform.translation.y",
                [0, 1.5, 4, 5.5, 4.5, 2, 0.5, 0], total, times)
            add(leftPawLayer, "transform.rotation.z",
                [0, 0.04, 0.1, 0.15, 0.1, 0.04, -0.01, 0], total, times)
            add(rightPawLayer, "transform.rotation.z",
                [0, -0.04, -0.1, -0.15, -0.1, -0.04, 0.01, 0], total, times)
            add(tailLayer, "transform.rotation.z",
                [0, 0.07, 0.15, 0.21, 0.14, 0.05, -0.025, 0], total, times)
            addShadowPulse(scale: [1, 1.02, 1.07, 1.1, 1.07, 1.02, 0.99, 1],
                           opacity: [0.68, 0.69, 0.7, 0.69, 0.68, 0.67, 0.67, 0.68],
                           duration: total,
                           keyTimes: times)
        }
    }

    private func add(_ target: CALayer,
                     _ keyPath: String,
                     _ values: [CGFloat],
                     _ duration: TimeInterval,
                     _ keyTimes: [NSNumber]? = nil,
                     additive: Bool = true,
                     repeatCount: Float = 0,
                     key: String? = nil) {
        target.add(keyframe(keyPath,
                            values: values,
                            duration: duration,
                            keyTimes: keyTimes,
                            additive: additive,
                            repeatCount: repeatCount),
                   forKey: key ?? keyPath)
    }

    private func startIdleMotion() {
        add(sittingCoreLayer, "transform.translation.y", [0, 0.6, 0], 2.7,
            repeatCount: .infinity, key: "idleWeight")
        add(bodyLayer, "transform.scale.y", [0.998, 1.01, 0.998], 2.7,
            additive: false, repeatCount: .infinity, key: "idleBreath")
        add(headLayer, "transform.rotation.z", [0, 0.012, 0], 2.7,
            repeatCount: .infinity, key: "idleHeadBalance")
        add(haunchLayer, "transform.scale.x", [1, 1.008, 1], 2.7,
            additive: false, repeatCount: .infinity, key: "idleHaunch")
        add(tailLayer, "transform.rotation.z", [-0.045, 0.065, -0.045], 2.8,
            repeatCount: .infinity, key: "idleTail")
        addShadowPulse(scale: [0.97, 1.03, 0.97],
                       opacity: [0.64, 0.72, 0.64],
                       duration: 2.5,
                       repeatForever: true)
    }

    private func startWalkCycle() {
        guard !isWalking, currentMood == .idle else { return }
        clearActionMotion()
        isWalking = true
        petState = .walking
        currentAction = nil
        setWalkingPose(true, animated: true)
        showPoseFrames(walkPoseFrames, duration: 0.72, repeatForever: true)
        let forever = Float.infinity
        let duration: TimeInterval = 0.86
        let phases: [NSNumber] = [0, 0.2, 0.5, 0.7, 1]

        // Opposing diagonal pairs alternate between a planted stance and a lifted return swing.
        add(walkFrontLegLayer, "transform.rotation.z", [-0.095, 0.012, 0.09, 0.012, -0.095], duration, phases,
            repeatCount: forever, key: "walkFrontRotation")
        add(walkFrontLegLayer, "transform.translation.x", [1.0, 0, -1.0, 0, 1.0], duration, phases,
            repeatCount: forever, key: "walkFrontStride")
        add(walkFrontLegLayer, "transform.translation.y", [0, 0, 0.3, 2.4, 0], duration, phases,
            repeatCount: forever, key: "walkFrontLift")
        add(walkRearLegLayer, "transform.rotation.z", [0.085, -0.012, -0.085, -0.012, 0.085], duration, phases,
            repeatCount: forever, key: "walkRearRotation")
        add(walkRearLegLayer, "transform.translation.x", [-0.9, 0, 0.9, 0, -0.9], duration, phases,
            repeatCount: forever, key: "walkRearStride")
        add(walkRearLegLayer, "transform.translation.y", [0, 0, 0.3, 2.2, 0], duration, phases,
            repeatCount: forever, key: "walkRearLift")

        add(walkHindLegLayer, "transform.rotation.z", [-0.085, -0.012, 0.085, 0.012, -0.085], duration, phases,
            repeatCount: forever, key: "walkHindRotation")
        add(walkHindLegLayer, "transform.translation.x", [0.85, 0, -0.85, 0, 0.85], duration, phases,
            repeatCount: forever, key: "walkHindStride")
        add(walkHindLegLayer, "transform.translation.y", [0.3, 2.2, 0, 0, 0.3], duration, phases,
            repeatCount: forever, key: "walkHindLift")
        add(walkFrontDownLegLayer, "transform.rotation.z", [0.09, 0.012, -0.09, -0.012, 0.09], duration, phases,
            repeatCount: forever, key: "walkFrontDownRotation")
        add(walkFrontDownLegLayer, "transform.translation.x", [-0.95, 0, 0.95, 0, -0.95], duration, phases,
            repeatCount: forever, key: "walkFrontDownStride")
        add(walkFrontDownLegLayer, "transform.translation.y", [0.3, 2.3, 0, 0, 0.3], duration, phases,
            repeatCount: forever, key: "walkFrontDownLift")

        add(rigLayer, "transform.translation.y", [0, 0.7, 0, 0.7, 0], duration, phases,
            repeatCount: forever, key: "walkWeightShift")
        add(walkCoreLayer, "transform.translation.x", [0, 0.7, 0, -0.7, 0], duration, phases,
            repeatCount: forever, key: "walkCoreWeight")
        add(walkCoreLayer, "transform.rotation.z", [0.008, 0, -0.008, 0, 0.008], duration, phases,
            repeatCount: forever, key: "walkSpine")
        add(walkBodyLayer, "transform.scale.x", [1, 1.004, 1, 1.004, 1], duration, phases,
            additive: false, repeatCount: forever, key: "walkBodyStride")
        add(walkHeadLayer, "transform.rotation.z", [-0.003, 0.002, 0.003, -0.002, -0.003], duration, phases,
            repeatCount: forever, key: "walkHeadBalance")
        add(walkTailLayer, "transform.rotation.z", [-0.055, 0, 0.06, 0, -0.055], duration, phases,
            repeatCount: forever, key: "walkTail")
        addShadowPulse(scale: [1, 0.96, 1, 0.96, 1],
                       opacity: [0.74, 0.67, 0.74, 0.67, 0.74],
                       duration: duration,
                       keyTimes: phases,
                       repeatForever: true)
    }

    private func finishInteraction(after duration: TimeInterval) {
        settleTimer?.invalidate()
        settleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.showMood(.idle)
        }
    }

    private func reactToClick(at location: NSPoint) {
        let wasWalking = isWalking
        currentMood = .react
        petState = .idle
        currentAction = .react
        isWalking = false
        clearActionMotion()
        if wasWalking {
            setWalkingPose(false, animated: true)
        }
        let direction: CGFloat = location.x < bounds.midX ? -1 : 1
        let total: TimeInterval = 0.72
        let times: [NSNumber] = [0, 0.16, 0.42, 0.72, 1]

        add(headLayer, "transform.rotation.z",
            [0, direction * 0.025, direction * 0.04, -direction * 0.012, 0], total, times)
        add(headLayer, "transform.translation.x",
            [0, direction * 2, direction * 3.5, direction, 0], total, times)
        add(headLayer, "transform.translation.y", [0, -1, 1.5, 0.5, 0], total, times)
        add(bodyLayer, "transform.scale.y", [1, 0.985, 1.012, 1.004, 1], total, times, additive: false)
        add(rigLayer, "transform.translation.y", [0, -1.5, 2.5, 1, 0], total, times)
        add(tailLayer, "transform.rotation.z",
            [0, -direction * 0.08, direction * 0.14, -direction * 0.045, 0], total, times)

        let respondingPaw = direction < 0 ? leftPawLayer : rightPawLayer
        add(respondingPaw, "transform.translation.y", [0, 3, 8, 3, 0], total, times)
        add(respondingPaw, "transform.rotation.z",
            [0, -direction * 0.025, -direction * 0.07, -direction * 0.02, 0], total, times)
        addShadowPulse(scale: [1, 1.03, 0.97, 1.01, 1],
                       opacity: [0.68, 0.72, 0.64, 0.69, 0.68],
                       duration: total,
                       keyTimes: times)
        showPose(.react, duration: total)
        finishInteraction(after: total)
    }

    private func settleAfterDrag() {
        currentMood = .react
        petState = .idle
        currentAction = .react
        isWalking = false
        clearActionMotion()
        let total: TimeInterval = 0.46
        let times: [NSNumber] = [0, 0.28, 0.62, 1]
        add(rigLayer, "transform.translation.y", [4, -2, 1, 0], total, times)
        add(bodyLayer, "transform.scale.y", [1.02, 0.975, 1.008, 1], total, times, additive: false)
        add(leftPawLayer, "transform.rotation.z", [-0.04, 0.035, -0.012, 0], total, times)
        add(rightPawLayer, "transform.rotation.z", [0.04, -0.035, 0.012, 0], total, times)
        add(tailLayer, "transform.rotation.z", [0.08, -0.05, 0.02, 0], total, times)
        showPose(.react, duration: total)
        finishInteraction(after: total)
    }

    private func stopWalkCycle() {
        guard isWalking else { return }
        isWalking = false
        petState = .idle
        clearActionMotion()
        setWalkingPose(false, animated: true)
        startIdleMotion()
        showPose(.idle, duration: 2.8, repeatForever: true)
    }

    private func addShadowPulse(scale: [CGFloat],
                                opacity: [CGFloat],
                                duration: TimeInterval,
                                keyTimes: [NSNumber]? = nil,
                                repeatForever: Bool = false) {
        let shadowScale = keyframe("transform.scale.x",
                                   values: scale,
                                   duration: duration,
                                   keyTimes: keyTimes,
                                   additive: false)
        let shadowOpacity = keyframe("opacity",
                                     values: opacity,
                                     duration: duration,
                                     keyTimes: keyTimes,
                                     additive: false)
        if repeatForever {
            shadowScale.repeatCount = .infinity
            shadowOpacity.repeatCount = .infinity
        }
        shadowLayer.add(shadowScale, forKey: "actionShadowScale")
        shadowLayer.add(shadowOpacity, forKey: "actionShadowOpacity")
    }

    func setMotionTilt(dx: CGFloat, dy: CGFloat) {
        guard currentMood == .idle else { return }
        let moving = hypot(dx, dy) > 0.5
        if moving {
            startWalkCycle()
        } else {
            stopWalkCycle()
        }
        let limitedX = max(-1.0, min(1.0, dx / 4.0))
        let transform = CATransform3DMakeScale(limitedX < 0 ? -1 : 1, 1, 1)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rigLayer.transform = transform
        shadowLayer.opacity = Float(0.6 + min(0.12, abs(limitedX) * 0.1))
        CATransaction.commit()
    }

    override func mouseDown(with event: NSEvent) {
        dragStartPoint = event.locationInWindow
        dragStartWindowOrigin = window?.frame.origin ?? .zero
        wasDragged = false
        controller?.pauseMovement()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window else { return }
        let current = event.locationInWindow
        let dx = current.x - dragStartPoint.x
        let dy = current.y - dragStartPoint.y
        if hypot(dx, dy) > 3 {
            wasDragged = true
        }
        window.setFrameOrigin(NSPoint(x: dragStartWindowOrigin.x + dx, y: dragStartWindowOrigin.y + dy))
    }

    override func mouseUp(with event: NSEvent) {
        controller?.resumeMovementAfterInteraction()
        if wasDragged {
            settleAfterDrag()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let menu = controller?.makeMenu() else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc func clickReact() {
        let windowPoint = window?.mouseLocationOutsideOfEventStream ?? NSPoint(x: bounds.midX, y: bounds.midY)
        reactToClick(at: convert(windowPoint, from: nil))
        controller?.receiveClick()
    }

    func runInteractionPreview() {
        reactToClick(at: NSPoint(x: bounds.midX * 0.72, y: bounds.midY))
    }

    func runActionPreview(named name: String) {
        switch name {
        case "blink": play(.blink, frameDuration: 0.12, loops: 2)
        case "groom": play(.groom, frameDuration: 0.15, loops: 1)
        case "scratch": play(.scratch, frameDuration: 0.11, loops: 1)
        case "jump": play(.jump, frameDuration: 0.12, loops: 1)
        case "sleep": startSleeping()
        case "roll": play(.roll, frameDuration: 0.12, loops: 1)
        case "tap": runInteractionPreview()
        default: break
        }
    }
}


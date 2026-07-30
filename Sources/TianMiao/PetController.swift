import Cocoa
import ServiceManagement
import UserNotifications

final class PetController: NSObject {
    private(set) var window: TianMiaoWindow!
    private(set) var catView: CatView!
    private let bubbleWindow = BubbleWindow()
    private var movementTimer: Timer?
    private var behaviorTimer: Timer?
    private var reminderTimer: Timer?
    private var decayTimer: Timer?
    private var focusTimer: Timer?
    private var previewTimer: Timer?
    private var velocity = CGVector(dx: -1.45, dy: 0)
    private var isRoamWalking = true
    private var gaitPhase: CGFloat = 0
    private var roamTransitionAt = Date().addingTimeInterval(5)
    private var settings = PetSettings.load()
    private var stats = PetStats.load()
    private var focusSession = FocusSession.load()
    private let baseSize = NSSize(width: 360, height: 392)
    func start() {
        let size = currentSize()
        window = TianMiaoWindow(contentRect: NSRect(origin: initialOrigin(size: size), size: size))
        window.level = settings.alwaysOnTop ? .floating : .normal
        catView = CatView(frame: NSRect(origin: .zero, size: size), controller: self)
        window.contentView = catView

        window.makeKeyAndOrderFront(nil)
        startMovement()
        startAmbientBehaviors()
        startGentleReminders()
        startNeedsDecay()
        restoreFocusSession()
        showBubble(stats.moodLine)
        if ProcessInfo.processInfo.environment["TIANMIAO_PREVIEW_INTERACTION"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.perform(.tap, updateStats: false, showFeedback: false)
            }
        }
        if let actionName = ProcessInfo.processInfo.environment["TIANMIAO_PREVIEW_ACTION"],
           let command = PetCommand(rawValue: actionName) {
            let delay = Double(ProcessInfo.processInfo.environment["TIANMIAO_PREVIEW_DELAY"] ?? "") ?? 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.perform(command, updateStats: false, showFeedback: false)
                if ProcessInfo.processInfo.environment["TIANMIAO_PREVIEW_LOOP"] == "1" {
                    self?.previewTimer = Timer.scheduledTimer(
                        withTimeInterval: 2.4,
                        repeats: true
                    ) { [weak self] _ in
                        self?.perform(command, updateStats: false, showFeedback: false)
                    }
                }
            }
        }
        if ProcessInfo.processInfo.environment["TIANMIAO_PREVIEW_FOCUS"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.startFocus()
            }
        }
        if ProcessInfo.processInfo.environment["TIANMIAO_PREVIEW_REMINDER"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.showReminder("提醒降级测试")
            }
        }
        if ProcessInfo.processInfo.environment["TIANMIAO_PREVIEW_UPDATE_CHECK"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.checkLatestRelease()
            }
        }
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        let status = NSMenuItem(title: stats.compactLine, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(NSMenuItem(title: "看状态", action: #selector(showStatus), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "喂小鱼干", action: #selector(feed), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "陪它玩", action: #selector(playTogether), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "摸摸头", action: #selector(pat), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(item("自由游走", action: #selector(setRoam), checked: settings.mode == .roam))
        menu.addItem(item("跟随鼠标", action: #selector(setFollow), checked: settings.mode == .follow))
        menu.addItem(item("角落休息", action: #selector(setCorner), checked: settings.mode == .corner))
        menu.addItem(NSMenuItem(title: "召唤到鼠标旁", action: #selector(summonToMouse), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(item("小一点", action: #selector(sizeSmall), checked: abs(settings.scale - 0.40) < 0.01))
        menu.addItem(item("标准大小", action: #selector(sizeNormal), checked: abs(settings.scale - 0.48) < 0.01))
        menu.addItem(item("大一点", action: #selector(sizeLarge), checked: abs(settings.scale - 0.57) < 0.01))
        menu.addItem(.separator())
        menu.addItem(item("慢悠悠", action: #selector(speedSlow), checked: settings.speed == 0.65))
        menu.addItem(item("正常速度", action: #selector(speedNormal), checked: settings.speed == 1.0))
        menu.addItem(item("精神一点", action: #selector(speedFast), checked: settings.speed == 1.45))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "梳毛", action: #selector(groom), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "挠一挠", action: #selector(scratch), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "跳一下", action: #selector(jump), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "睡觉", action: #selector(sleep), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "打个滚", action: #selector(roll), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(item("置顶显示", action: #selector(toggleAlwaysOnTop), checked: settings.alwaysOnTop))
        menu.addItem(item("休息提醒", action: #selector(toggleReminders), checked: settings.remindersEnabled))
        menu.addItem(item("勿扰模式", action: #selector(toggleDoNotDisturb), checked: settings.doNotDisturb))
        menu.addItem(item("登录时启动",
                          action: #selector(toggleLaunchAtLogin),
                          checked: SMAppService.mainApp.status == .enabled))
        let updateItem = NSMenuItem(
            title: "检查新版…",
            action: #selector(checkLatestRelease),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)
        if focusSession.isActive {
            let focusStatus = NSMenuItem(title: focusSession.remainingLine, action: nil, keyEquivalent: "")
            focusStatus.isEnabled = false
            menu.addItem(focusStatus)
            menu.addItem(NSMenuItem(title: "取消专注", action: #selector(cancelFocus), keyEquivalent: ""))
        } else {
            menu.addItem(NSMenuItem(title: "开始 25 分钟专注", action: #selector(startFocus), keyEquivalent: ""))
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出甜喵物语", action: #selector(quit), keyEquivalent: "q"))
        for menuItem in menu.items where menuItem.action != nil && menuItem.target == nil {
            menuItem.target = self
        }
        applyCuteMenuTypography(to: menu)
        return menu
    }

    private func applyCuteMenuTypography(to menu: NSMenu) {
        let font = NSFont(name: "Wawati SC", size: 14)
            ?? NSFont(name: "Hannotate SC", size: 13.5)
            ?? NSFont.systemFont(ofSize: 13.5, weight: .semibold)
        for menuItem in menu.items where !menuItem.isSeparatorItem && !menuItem.title.isEmpty {
            menuItem.attributedTitle = NSAttributedString(
                string: menuItem.title,
                attributes: [.font: font]
            )
        }
    }

    private func item(_ title: String, action: Selector, checked: Bool) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: "")
        menuItem.state = checked ? .on : .off
        menuItem.target = self
        return menuItem
    }

    private func currentSize() -> NSSize {
        NSSize(width: baseSize.width * settings.scale, height: baseSize.height * settings.scale)
    }

    private func initialOrigin(size: NSSize) -> NSPoint {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return NSPoint(x: screen.maxX - size.width - 32, y: groundY(in: screen))
    }

    private func groundY(in screen: NSRect) -> CGFloat {
        screen.minY + 12
    }

    private func startMovement() {
        movementTimer?.invalidate()
        movementTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tickMovement()
        }
    }

    private func startAmbientBehaviors() {
        behaviorTimer?.invalidate()
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: 7.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            let roll = Int.random(in: 0..<100)
            if roll < 34 {
                self.catView.playIfIdle(.blink, frameDuration: 0.11, loops: 1)
            } else if roll < 50 {
                self.catView.playIfIdle(.groom, frameDuration: 0.16, loops: 1)
            } else if roll < 64 {
                self.catView.playIfIdle(.scratch, frameDuration: 0.11, loops: 1)
            } else if roll < 74 {
                self.catView.playIfIdle(.jump, frameDuration: 0.12, loops: 1)
            } else if roll < 82 {
                self.catView.playIfIdle(.roll, frameDuration: 0.12, loops: 1)
            } else if roll < 88 {
                self.catView.startSleeping(for: Double.random(in: 5.0...9.0))
            } else {
                self.showBubble(self.stats.moodLine)
            }
        }
    }

    private func startGentleReminders() {
        reminderTimer?.invalidate()
        guard settings.remindersEnabled else { return }
        requestNotificationAuthorizationIfNeeded()
        reminderTimer = Timer.scheduledTimer(withTimeInterval: 45 * 60, repeats: true) { [weak self] _ in
            self?.showReminder("休息一下，喝口水")
        }
    }

    private func requestNotificationAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    private func startNeedsDecay() {
        decayTimer?.invalidate()
        decayTimer = Timer.scheduledTimer(withTimeInterval: 8 * 60, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.stats.decayTick()
            if self.stats.hunger < 26 {
                self.showBubble("有点饿，想吃小鱼干")
            } else if self.stats.energy < 24 {
                self.catView.startSleeping()
                self.showBubble("甜喵有点困")
            } else if self.stats.happiness < 28 {
                self.showBubble("想被陪一下")
            }
        }
    }

    private func tickMovement() {
        guard let window else { return }
        defer {
            bubbleWindow.reposition(near: window.frame, walking: catView.isWalkingPose)
        }
        guard !catView.isPerformingAction else { return }
        switch settings.mode {
        case .roam:
            roam(window)
        case .follow:
            followMouse(window)
        case .corner:
            moveTowardCorner(window)
        }
    }

    private func roam(_ window: NSWindow) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        var frame = window.frame
        frame.origin.y += (groundY(in: screen) - frame.origin.y) * 0.16

        if catView.isPerformingAction {
            window.setFrameOrigin(frame.origin)
            return
        }

        if Date() >= roamTransitionAt {
            isRoamWalking.toggle()
            if isRoamWalking {
                let magnitude = CGFloat.random(in: 1.15...1.7)
                velocity.dx = Bool.random() ? magnitude : -magnitude
                gaitPhase = 0
                roamTransitionAt = Date().addingTimeInterval(Double.random(in: 4.5...9.0))
            } else {
                roamTransitionAt = Date().addingTimeInterval(Double.random(in: 1.8...4.5))
            }
        }

        guard isRoamWalking else {
            catView.setMotionTilt(dx: 0, dy: 0)
            window.setFrameOrigin(frame.origin)
            return
        }

        frame.origin.x += velocity.dx * settings.speed * 0.58 * nextStrideMultiplier()

        if frame.minX < screen.minX || frame.maxX > screen.maxX {
            velocity.dx *= -1
            frame.origin.x = min(max(frame.origin.x, screen.minX), screen.maxX - frame.width)
            isRoamWalking = false
            roamTransitionAt = Date().addingTimeInterval(Double.random(in: 0.8...1.8))
        }
        catView.setMotionTilt(dx: velocity.dx, dy: 0)
        window.setFrameOrigin(frame.origin)
    }

    private func followMouse(_ window: NSWindow) {
        let mouse = NSEvent.mouseLocation
        let frame = window.frame
        let screen = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let target = NSPoint(x: min(max(mouse.x - frame.width / 2, screen.minX), screen.maxX - frame.width),
                             y: groundY(in: screen))
        catView.setMotionTilt(dx: target.x - frame.origin.x, dy: 0)
        move(window, toward: target, easing: 0.045 * settings.speed)
    }

    private func moveTowardCorner(_ window: NSWindow) {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let target = NSPoint(x: screen.maxX - window.frame.width - 28, y: groundY(in: screen))
        catView.setMotionTilt(dx: target.x - window.frame.origin.x, dy: 0)
        move(window, toward: target, easing: 0.05)
        if abs(target.x - window.frame.origin.x) < 1.0 {
            catView.startSleeping()
        }
    }

    private func move(_ window: NSWindow, toward target: NSPoint, easing: CGFloat) {
        var origin = window.frame.origin
        let dx = target.x - origin.x
        origin.x += dx * easing * (abs(dx) > 0.5 ? nextStrideMultiplier() : 1)
        origin.y += (target.y - origin.y) * easing
        window.setFrameOrigin(origin)
    }

    private func nextStrideMultiplier() -> CGFloat {
        gaitPhase += (.pi * 2) / (0.72 * 60)
        if gaitPhase >= .pi * 2 {
            gaitPhase -= .pi * 2
        }
        // Slow at paw contact and accelerate through the push-off phase.
        return 0.58 + 0.62 * abs(sin(gaitPhase))
    }

    func pauseMovement() {
        movementTimer?.invalidate()
    }

    func resumeMovementAfterInteraction() {
        if settings.mode == .roam {
            isRoamWalking = true
            roamTransitionAt = Date().addingTimeInterval(Double.random(in: 4.5...8.0))
        }
        startMovement()
    }

    func nudgeAwayFromMouse() {
        guard let window else { return }
        let mouse = NSEvent.mouseLocation
        let center = NSPoint(x: window.frame.midX, y: window.frame.midY)
        velocity = CGVector(dx: center.x >= mouse.x ? 1.7 : -1.7, dy: 0)
    }

    func receiveClick() {
        catView.wakeUp()
        stats.adjust(happiness: 2)
        if Int.random(in: 0..<3) == 0 {
            showBubble(["在呢", "喵", stats.moodLine].randomElement() ?? "喵")
        }
    }

    func showBubble(_ message: String, seconds: TimeInterval = 3.2) {
        guard !settings.doNotDisturb, let window else { return }
        bubbleWindow.level = settings.alwaysOnTop ? .floating : .normal
        bubbleWindow.show(message, near: window.frame, walking: catView.isWalkingPose, for: seconds)
    }

    private func showReminder(_ message: String) {
        guard settings.remindersEnabled, !settings.doNotDisturb else { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] notificationSettings in
            guard let self else { return }
            switch notificationSettings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                let content = UNMutableNotificationContent()
                content.title = "甜喵物语"
                content.body = message
                content.sound = .default
                let request = UNNotificationRequest(
                    identifier: "tianmiao-break-\(Date().timeIntervalSince1970)",
                    content: content,
                    trigger: nil
                )
                center.add(request) { [weak self] error in
                    guard error != nil else { return }
                    DispatchQueue.main.async {
                        self?.showReminderFallback(message)
                    }
                }
            case .denied, .notDetermined:
                DispatchQueue.main.async {
                    self.showReminderFallback(message)
                }
            @unknown default:
                DispatchQueue.main.async {
                    self.showReminderFallback(message)
                }
            }
        }
        catView.play(.blink, frameDuration: 0.12, loops: 2)
    }

    private func showReminderFallback(_ message: String) {
        guard settings.remindersEnabled, !settings.doNotDisturb else { return }
        showBubble(message, seconds: 5.0)
    }

    private func applySettings() {
        settings.save()
        let size = currentSize()
        guard let window else { return }
        window.level = settings.alwaysOnTop ? .floating : .normal
        window.setFrame(NSRect(origin: window.frame.origin, size: size), display: true, animate: true)
        catView.frame = NSRect(origin: .zero, size: size)
        if settings.mode == .corner {
            moveTowardCorner(window)
        }
        startMovement()
    }

    @objc private func setRoam() {
        catView.cancelActionAndWake()
        settings.mode = .roam
        isRoamWalking = true
        roamTransitionAt = Date().addingTimeInterval(Double.random(in: 4.5...8.0))
        applySettings()
        showBubble("我去逛逛")
    }

    @objc private func setFollow() {
        catView.cancelActionAndWake()
        settings.mode = .follow
        applySettings()
        showBubble("跟着你走")
    }

    @objc private func setCorner() {
        catView.cancelActionAndWake()
        settings.mode = .corner
        applySettings()
        catView.play(.blink, frameDuration: 0.18, loops: 2)
        showBubble("我在角落陪你")
    }

    @objc private func sizeSmall() {
        settings.scale = 0.40
        applySettings()
        showBubble("变小一点")
    }

    @objc private func sizeNormal() {
        settings.scale = 0.48
        applySettings()
        showBubble("标准大小")
    }

    @objc private func sizeLarge() {
        settings.scale = 0.57
        applySettings()
        showBubble("变大一点")
    }

    @objc private func speedSlow() {
        settings.speed = 0.65
        applySettings()
        showBubble("慢悠悠")
    }

    @objc private func speedNormal() {
        settings.speed = 1.0
        applySettings()
        showBubble("正常速度")
    }

    @objc private func speedFast() {
        settings.speed = 1.45
        applySettings()
        showBubble("精神起来了")
    }

    @objc private func groom() {
        perform(.groom)
    }

    @objc private func scratch() {
        perform(.scratch)
    }

    @objc private func jump() {
        perform(.jump)
    }

    @objc private func sleep() {
        perform(.sleep)
    }

    @objc private func roll() {
        perform(.roll)
    }

    @objc private func showStatus() {
        showBubble("\(stats.moodLine)\n\(stats.compactLine)", seconds: 5.0)
    }

    @objc private func feed() {
        perform(.feed)
    }

    @objc private func playTogether() {
        perform(.play)
    }

    @objc private func pat() {
        perform(.pat)
    }

    func perform(_ command: PetCommand,
                 updateStats: Bool = true,
                 showFeedback: Bool = true) {
        catView.cancelActionAndWake()
        let feedback: String
        switch command {
        case .blink:
            catView.play(.blink, frameDuration: 0.12, loops: 2)
            feedback = "眨眨眼"
        case .groom:
            if updateStats { stats.adjust(happiness: 3, energy: -1) }
            catView.play(.groom, frameDuration: 0.15, loops: 2)
            feedback = "把毛整理好"
        case .scratch:
            if updateStats { stats.adjust(happiness: 4, energy: -2) }
            catView.play(.scratch, frameDuration: 0.11, loops: 1)
            feedback = "磨磨小爪子"
        case .jump:
            if updateStats { stats.adjust(happiness: 3, energy: -2) }
            catView.play(.jump, frameDuration: 0.12, loops: 1)
            feedback = "跳一下"
        case .sleep:
            catView.startSleeping()
            feedback = "睡一小会儿"
        case .roll:
            if updateStats { stats.adjust(happiness: 5, energy: -3) }
            catView.play(.roll, frameDuration: 0.12, loops: 1)
            feedback = "打个滚"
        case .feed:
            if updateStats { stats.adjust(hunger: 18, happiness: 5, energy: 2) }
            catView.play(.groom, frameDuration: 0.13, loops: 1)
            feedback = "小鱼干真好吃"
        case .play:
            if updateStats { stats.adjust(hunger: -5, happiness: 16, energy: -8) }
            catView.runInteractionPreview()
            nudgeAwayFromMouse()
            feedback = "再玩一下"
        case .pat:
            if updateStats { stats.adjust(happiness: 10, energy: 2) }
            catView.play(.blink, frameDuration: 0.1, loops: 2)
            feedback = "呼噜呼噜"
        case .tap:
            catView.runInteractionPreview()
            feedback = "在呢"
        }
        if showFeedback {
            showBubble(feedback)
        }
    }

    @objc private func summonToMouse() {
        guard let window else { return }
        let mouse = NSEvent.mouseLocation
        let screen = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(x: min(max(mouse.x - window.frame.width / 2, screen.minX), screen.maxX - window.frame.width),
                             y: groundY(in: screen))
        window.setFrameOrigin(origin)
        settings.mode = .follow
        settings.save()
        startMovement()
        showBubble("我来了")
    }

    @objc private func toggleAlwaysOnTop() {
        settings.alwaysOnTop.toggle()
        settings.save()
        window.level = settings.alwaysOnTop ? .floating : .normal
        showBubble(settings.alwaysOnTop ? "继续置顶" : "不挡你了")
    }

    @objc private func toggleReminders() {
        settings.remindersEnabled.toggle()
        settings.save()
        startGentleReminders()
        showBubble(settings.remindersEnabled ? "休息提醒已开启" : "休息提醒已关闭")
    }

    @objc private func toggleDoNotDisturb() {
        settings.doNotDisturb.toggle()
        settings.save()
        if settings.doNotDisturb {
            bubbleWindow.orderOut(nil)
        } else {
            showBubble("勿扰已关闭")
        }
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            switch service.status {
            case .enabled:
                try service.unregister()
                showBubble("已关闭登录时启动")
            case .requiresApproval:
                SMAppService.openSystemSettingsLoginItems()
                showBubble("请在系统设置中允许甜喵物语")
            case .notRegistered, .notFound:
                try service.register()
                if service.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                    showBubble("请在系统设置中允许甜喵物语")
                } else {
                    showBubble("已开启登录时启动")
                }
            @unknown default:
                SMAppService.openSystemSettingsLoginItems()
                showBubble("请在系统设置中检查登录项")
            }
        } catch {
            showBubble("登录启动设置失败：\(error.localizedDescription)", seconds: 5.0)
        }
    }

    @objc private func checkLatestRelease() {
        guard let url = URL(string: "https://github.com/Cyidid/tianmiao-story/releases/latest") else {
            showBubble("新版页面地址无效")
            return
        }
        if !NSWorkspace.shared.open(url) {
            showBubble("无法打开新版页面")
        }
    }

    @objc private func startFocus() {
        focusTimer?.invalidate()
        let duration = Double(ProcessInfo.processInfo.environment["TIANMIAO_FOCUS_DURATION_SECONDS"] ?? "") ?? 25 * 60
        focusSession.start(duration: max(1, duration))
        settings.mode = .corner
        settings.save()
        applySettings()
        catView.play(.blink, frameDuration: 0.18, loops: 2)
        showBubble("开始 25 分钟专注", seconds: 4.0)
        scheduleFocusCompletion()
    }

    @objc private func cancelFocus() {
        focusTimer?.invalidate()
        focusSession.cancel()
        catView.wakeUp()
        settings.mode = .roam
        applySettings()
        showBubble("专注已取消")
    }

    private func restoreFocusSession() {
        guard focusSession.isActive else { return }
        settings.mode = .corner
        settings.save()
        applySettings()
        scheduleFocusCompletion()
    }

    private func scheduleFocusCompletion() {
        focusTimer?.invalidate()
        let delay = max(0, focusSession.endDate?.timeIntervalSinceNow ?? 0)
        guard delay > 0 else {
            completeFocusSession()
            return
        }
        focusTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.completeFocusSession()
        }
    }

    private func completeFocusSession() {
        guard focusSession.endDate != nil else { return }
        focusSession.cancel()
        stats.adjust(happiness: 6, energy: 6)
        catView.wakeUp()
        showReminder("专注结束，起来活动一下")
        catView.play(.blink, frameDuration: 0.11, loops: 2)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

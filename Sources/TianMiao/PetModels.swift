import Cocoa

enum PetMode: String {
    case roam
    case follow
    case corner
}

enum PetMood: String {
    case idle
    case blink
    case react
    case groom
    case scratch
    case jump
    case sleep
    case roll
}

enum PetState: String {
    case idle
    case walking
    case sleeping
}

enum PetAction: String {
    case blink
    case react
    case groom
    case scratch
    case jump
    case roll
}

struct PetSettings {
    static let modeKey = "mode"
    static let scaleKey = "scale"
    static let scaleVersionKey = "scaleVersion"
    static let speedKey = "speed"
    static let remindersEnabledKey = "remindersEnabled"
    static let doNotDisturbKey = "doNotDisturb"
    static let alwaysOnTopKey = "alwaysOnTop"

    var mode: PetMode
    var scale: CGFloat
    var speed: CGFloat
    var remindersEnabled: Bool
    var doNotDisturb: Bool
    var alwaysOnTop: Bool

    static func load() -> PetSettings {
        let defaults = UserDefaults.standard
        let mode = PetMode(rawValue: defaults.string(forKey: modeKey) ?? "") ?? .roam
        let storedScale = defaults.object(forKey: scaleKey) as? Double
        let scaleVersion = defaults.integer(forKey: scaleVersionKey)
        let scaleValue = Self.normalizedScale(storedScale, version: scaleVersion)
        if scaleVersion < 3 {
            defaults.set(scaleValue, forKey: scaleKey)
            defaults.set(3, forKey: scaleVersionKey)
        }
        let speedValue = defaults.object(forKey: speedKey) as? Double ?? 1.0
        let reminders = defaults.object(forKey: remindersEnabledKey) as? Bool ?? true
        let dnd = defaults.object(forKey: doNotDisturbKey) as? Bool ?? false
        let alwaysOnTop = defaults.object(forKey: alwaysOnTopKey) as? Bool ?? true
        return PetSettings(mode: mode,
                           scale: CGFloat(scaleValue),
                           speed: CGFloat(speedValue),
                           remindersEnabled: reminders,
                           doNotDisturb: dnd,
                           alwaysOnTop: alwaysOnTop)
    }

    private static func normalizedScale(_ storedScale: Double?, version: Int) -> Double {
        guard let storedScale else { return 0.52 }
        if version < 3 {
            if storedScale <= 0.28 { return 0.44 }
            if storedScale <= 0.36 { return 0.52 }
            return 0.62
        }
        return min(0.66, max(0.40, storedScale))
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(mode.rawValue, forKey: PetSettings.modeKey)
        defaults.set(Double(scale), forKey: PetSettings.scaleKey)
        defaults.set(3, forKey: PetSettings.scaleVersionKey)
        defaults.set(Double(speed), forKey: PetSettings.speedKey)
        defaults.set(remindersEnabled, forKey: PetSettings.remindersEnabledKey)
        defaults.set(doNotDisturb, forKey: PetSettings.doNotDisturbKey)
        defaults.set(alwaysOnTop, forKey: PetSettings.alwaysOnTopKey)
    }
}

struct PetStats {
    static let hungerKey = "hunger"
    static let happinessKey = "happiness"
    static let energyKey = "energy"
    static let lastUpdatedKey = "lastUpdated"

    var hunger: Int
    var happiness: Int
    var energy: Int
    var lastUpdated: Date

    static func load() -> PetStats {
        let defaults = UserDefaults.standard
        var stats = PetStats(
            hunger: defaults.object(forKey: hungerKey) as? Int ?? 74,
            happiness: defaults.object(forKey: happinessKey) as? Int ?? 78,
            energy: defaults.object(forKey: energyKey) as? Int ?? 82,
            lastUpdated: defaults.object(forKey: lastUpdatedKey) as? Date ?? Date()
        )
        stats.applyOfflineDecay()
        stats.save()
        return stats
    }

    var moodLine: String {
        if hunger < 30 { return "有点饿" }
        if energy < 28 { return "想睡觉" }
        if happiness < 35 { return "想被陪一下" }
        if hunger > 82 && happiness > 82 && energy > 72 { return "状态很好" }
        return "安静陪你"
    }

    var compactLine: String {
        "饱腹 \(hunger)%  开心 \(happiness)%  精力 \(energy)%"
    }

    mutating func adjust(hunger hungerDelta: Int = 0, happiness happinessDelta: Int = 0, energy energyDelta: Int = 0) {
        hunger = Self.clamp(hunger + hungerDelta)
        happiness = Self.clamp(happiness + happinessDelta)
        energy = Self.clamp(energy + energyDelta)
        lastUpdated = Date()
        save()
    }

    mutating func decayTick() {
        adjust(hunger: -1, happiness: -1, energy: -1)
    }

    mutating func applyOfflineDecay() {
        let minutes = Int(Date().timeIntervalSince(lastUpdated) / 60)
        guard minutes >= 20 else { return }
        let steps = min(18, minutes / 20)
        hunger = Self.clamp(hunger - steps)
        happiness = Self.clamp(happiness - max(1, steps / 2))
        energy = Self.clamp(energy - max(1, steps / 2))
        lastUpdated = Date()
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(hunger, forKey: Self.hungerKey)
        defaults.set(happiness, forKey: Self.happinessKey)
        defaults.set(energy, forKey: Self.energyKey)
        defaults.set(lastUpdated, forKey: Self.lastUpdatedKey)
    }

    private static func clamp(_ value: Int) -> Int {
        min(100, max(0, value))
    }
}

struct FocusSession {
    static let endDateKey = "focusEndDate"

    private(set) var endDate: Date?

    static func load() -> FocusSession {
        let defaults = UserDefaults.standard
        guard let endDate = defaults.object(forKey: endDateKey) as? Date,
              endDate > Date() else {
            defaults.removeObject(forKey: endDateKey)
            return FocusSession(endDate: nil)
        }
        return FocusSession(endDate: endDate)
    }

    var isActive: Bool {
        remainingSeconds > 0
    }

    var remainingSeconds: Int {
        guard let endDate else { return 0 }
        return max(0, Int(ceil(endDate.timeIntervalSinceNow)))
    }

    var remainingLine: String {
        let seconds = remainingSeconds
        return String(format: "专注剩余 %02d:%02d", seconds / 60, seconds % 60)
    }

    mutating func start(duration: TimeInterval) {
        endDate = Date().addingTimeInterval(duration)
        UserDefaults.standard.set(endDate, forKey: Self.endDateKey)
    }

    mutating func cancel() {
        endDate = nil
        UserDefaults.standard.removeObject(forKey: Self.endDateKey)
    }
}


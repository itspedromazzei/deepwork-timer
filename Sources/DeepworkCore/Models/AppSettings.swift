import Foundation

public enum WindowMode: String, Codable, Sendable {
    case floating
    case cover
}

/// Todas as preferências do usuário. Decodifica com defaults para que
/// chaves novas nunca quebrem um settings.json antigo.
public struct AppSettings: Codable, Equatable, Sendable {
    public var focusMinutes: Int = 50
    public var breakMinutes: Int = 10

    public var audioMode: AudioMode = .brown
    public var audioVolume: Double = 0.5
    public var audioDuringBreak: Bool = false
    public var binauralBeatHz: Double = 18
    public var binauralCarrierHz: Double = 200

    public var bellVolume: Double = 0.8
    public var countdownTicks: Bool = true

    public var autoStartBreak: Bool = true
    public var autoStartNextFocus: Bool = false
    public var keepAwake: Bool = true

    public var activities: [Activity] = Activity.seed()
    public var lastActivityID: UUID? = nil

    public var windowMode: WindowMode = .floating
    public var floatingFrame: String? = nil
    public var fullscreenDisplayID: UInt32? = nil
    public var fullscreenDisplayName: String? = nil

    public init() {}

    public var focusSeconds: Int { focusMinutes * 60 }
    public var breakSeconds: Int { breakMinutes * 60 }

    public var activeActivities: [Activity] { activities.filter { !$0.archived } }

    public var lastActivity: Activity? {
        if let id = lastActivityID, let a = activities.first(where: { $0.id == id && !$0.archived }) {
            return a
        }
        return activeActivities.first
    }

    enum CodingKeys: String, CodingKey {
        case focusMinutes, breakMinutes
        case audioMode, audioVolume, audioDuringBreak, binauralBeatHz, binauralCarrierHz
        case bellVolume, countdownTicks
        case autoStartBreak, autoStartNextFocus, keepAwake
        case activities, lastActivityID
        case windowMode, floatingFrame, fullscreenDisplayID, fullscreenDisplayName
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        focusMinutes = try c.decodeIfPresent(Int.self, forKey: .focusMinutes) ?? d.focusMinutes
        breakMinutes = try c.decodeIfPresent(Int.self, forKey: .breakMinutes) ?? d.breakMinutes
        audioMode = try c.decodeIfPresent(AudioMode.self, forKey: .audioMode) ?? d.audioMode
        audioVolume = try c.decodeIfPresent(Double.self, forKey: .audioVolume) ?? d.audioVolume
        audioDuringBreak = try c.decodeIfPresent(Bool.self, forKey: .audioDuringBreak) ?? d.audioDuringBreak
        binauralBeatHz = try c.decodeIfPresent(Double.self, forKey: .binauralBeatHz) ?? d.binauralBeatHz
        binauralCarrierHz = try c.decodeIfPresent(Double.self, forKey: .binauralCarrierHz) ?? d.binauralCarrierHz
        bellVolume = try c.decodeIfPresent(Double.self, forKey: .bellVolume) ?? d.bellVolume
        countdownTicks = try c.decodeIfPresent(Bool.self, forKey: .countdownTicks) ?? d.countdownTicks
        autoStartBreak = try c.decodeIfPresent(Bool.self, forKey: .autoStartBreak) ?? d.autoStartBreak
        autoStartNextFocus = try c.decodeIfPresent(Bool.self, forKey: .autoStartNextFocus) ?? d.autoStartNextFocus
        keepAwake = try c.decodeIfPresent(Bool.self, forKey: .keepAwake) ?? d.keepAwake
        activities = try c.decodeIfPresent([Activity].self, forKey: .activities) ?? d.activities
        lastActivityID = try c.decodeIfPresent(UUID.self, forKey: .lastActivityID)
        windowMode = try c.decodeIfPresent(WindowMode.self, forKey: .windowMode) ?? d.windowMode
        floatingFrame = try c.decodeIfPresent(String.self, forKey: .floatingFrame)
        fullscreenDisplayID = try c.decodeIfPresent(UInt32.self, forKey: .fullscreenDisplayID)
        fullscreenDisplayName = try c.decodeIfPresent(String.self, forKey: .fullscreenDisplayName)
    }
}

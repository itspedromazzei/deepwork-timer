import Foundation
import Observation
import DeepworkCore

struct ScreenInfo: Identifiable, Equatable {
    let id: UInt32
    let name: String
}

/// Estado de interface não persistente, compartilhado entre AppKit e SwiftUI.
@MainActor
@Observable
final class UIState {
    enum Overlay: Equatable {
        case none, settings, history, activities
    }

    var overlay: Overlay = .none
    var windowMode: WindowMode = .floating
    var controlsVisible = true
    var selectedActivityID: UUID?
    var screens: [ScreenInfo] = []
    var audioError: String?
    var isPreviewingAudio = false
}

/// Ações que as views disparam no AppDelegate.
struct AppActions {
    var startOrPause: () -> Void = {}
    var stop: () -> Void = {}
    var skipBreak: () -> Void = {}
    var toggleWindowMode: () -> Void = {}
    var previewAudio: () -> Void = {}
    var stopPreview: () -> Void = {}
    var previewBell: () -> Void = {}
    var audioSettingsChanged: () -> Void = {}
    var refreshScreens: () -> Void = {}
    var quit: () -> Void = {}
}

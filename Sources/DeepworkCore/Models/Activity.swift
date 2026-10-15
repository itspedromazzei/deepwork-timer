import Foundation

public struct Activity: Codable, Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    /// Índice na paleta de cores do app.
    public var colorIndex: Int
    public var archived: Bool

    public init(id: UUID = UUID(), name: String, colorIndex: Int = 0, archived: Bool = false) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
        self.archived = archived
    }

    public static let paletteSize = 8

    public static func seed() -> [Activity] {
        [
            Activity(name: "Meta Ads", colorIndex: 0),
            Activity(name: "Escrever", colorIndex: 1),
            Activity(name: "Reuniões", colorIndex: 2),
        ]
    }
}

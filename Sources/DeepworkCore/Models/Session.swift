import Foundation

public enum SessionKind: String, Codable, Sendable, Equatable {
    case focus
    case breakTime = "break"

    public var displayName: String {
        switch self {
        case .focus: return "Foco"
        case .breakTime: return "Pausa"
        }
    }
}

/// Um período de foco ou pausa já encerrado.
public struct Session: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let kind: SessionKind
    public let activityID: UUID?
    /// Nome da atividade no momento da sessão (sobrevive a renomeações).
    public let activityName: String
    public let startedAt: Date
    public var endedAt: Date
    public let plannedSeconds: Int
    /// Tempo efetivamente rodando, pausas excluídas.
    public var actualSeconds: Int
    /// true se chegou ao fim planejado; false se foi interrompida.
    public var completed: Bool

    public init(id: UUID = UUID(), kind: SessionKind, activityID: UUID?, activityName: String,
                startedAt: Date, endedAt: Date, plannedSeconds: Int, actualSeconds: Int, completed: Bool) {
        self.id = id
        self.kind = kind
        self.activityID = activityID
        self.activityName = activityName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedSeconds = plannedSeconds
        self.actualSeconds = actualSeconds
        self.completed = completed
    }
}

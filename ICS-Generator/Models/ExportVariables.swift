import Foundation

enum ExportVariable: String, CaseIterable {
    case eventTitle = "{title}"
    case eventYear = "{year}"
    case eventMonth = "{month}"
    case eventDay = "{day}"
    case timestamp = "{timestamp}"
    case currentDate = "{currentDate}"
    case eventCount = "{count}"
    
    var description: String {
        switch self {
        case .eventTitle:
            return "Titel des Events"
        case .eventYear:
            return "Jahr (YYYY)"
        case .eventMonth:
            return "Monat (MM)"
        case .eventDay:
            return "Tag (DD)"
        case .timestamp:
            return "Zeitstempel"
        case .currentDate:
            return "Aktuelles Datum"
        case .eventCount:
            return "Anzahl der Events"
        }
    }
    
    func value(for events: [ICSEvent]) -> String {
        let formatter = DateFormatter()
        
        switch self {
        case .eventTitle:
            return events.first?.title ?? "event"
        case .eventYear:
            formatter.dateFormat = "yyyy"
            return events.first.map { formatter.string(from: $0.startDate) } ?? "yyyy"
        case .eventMonth:
            formatter.dateFormat = "MM"
            return events.first.map { formatter.string(from: $0.startDate) } ?? "MM"
        case .eventDay:
            formatter.dateFormat = "dd"
            return events.first.map { formatter.string(from: $0.startDate) } ?? "dd"
        case .timestamp:
            return String(Int(Date().timeIntervalSince1970))
        case .currentDate:
            formatter.dateFormat = "yyyyMMdd"
            return formatter.string(from: Date())
        case .eventCount:
            return "\(events.count)"
        }
    }
}

class ExportSettings: ObservableObject {
    @Published var filenameTemplate: String {
        didSet {
            UserDefaults.standard.set(filenameTemplate, forKey: "ExportFilenameTemplate")
        }
    }
    
    init() {
        self.filenameTemplate = UserDefaults.standard.string(forKey: "ExportFilenameTemplate") ?? "{year}-{day}"
    }
    
    func generateFilename(for events: [ICSEvent]) -> String {
        var filename = filenameTemplate
        
        for variable in ExportVariable.allCases {
            filename = filename.replacingOccurrences(
                of: variable.rawValue,
                with: variable.value(for: events)
            )
        }
        
        // Entferne ungültige Zeichen
        filename = filename.replacingOccurrences(
            of: "[/\\\\?%*:|\"<>]",
            with: "_",
            options: .regularExpression
        )
        
        return filename
    }
}

import Foundation
import os.log

class ICSExporter {
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ICS-Generator", category: "ICSExporter")
    
    func exportEvents(_ events: [ICSEvent], to url: URL) throws {
        var components: [String] = []
        components.append("BEGIN:VCALENDAR")
        components.append("VERSION:2.0")
        components.append("PRODID:-//ICS Generator//DE")
        components.append("CALSCALE:GREGORIAN")
        components.append("METHOD:PUBLISH")
        
        for event in events {
            components.append("BEGIN:VEVENT")
            components.append("UID:\(event.id.uuidString)")
            components.append("DTSTAMP:\(formatDate(Date(), isAllDay: false))")
            components.append("SUMMARY:\(escapeString(event.title))")
            components.append("DTSTART\(event.isAllDay ? ";VALUE=DATE" : ""):\(formatDate(event.startDate, isAllDay: event.isAllDay))")
            components.append("DTEND\(event.isAllDay ? ";VALUE=DATE" : ""):\(formatDate(event.endDate, isAllDay: event.isAllDay))")
            
            if let location = event.location {
                components.append("LOCATION:\(escapeString(location))")
            }
            
            if let notes = event.notes {
                components.append("DESCRIPTION:\(escapeString(notes))")
            }
            
            if let url = event.url {
                components.append("URL:\(escapeString(url))")
            }
            
            if event.alert != .none {
                components.append("BEGIN:VALARM")
                components.append("ACTION:DISPLAY")
                components.append("DESCRIPTION:Reminder")
                components.append("TRIGGER:\(event.alert.triggerValue)")
                components.append("END:VALARM")
            }
            
            components.append("END:VEVENT")
        }
        
        components.append("END:VCALENDAR")
        
        let icsContent = components.joined(separator: "\r\n")
        
        // Validiere den ICS-Content
        switch ICSValidator.validate(icsContent) {
        case .success(let checks):
            let failedChecks = checks.filter { !$0.passed }
            if !failedChecks.isEmpty {
                let errors = failedChecks.map { "\($0.description): \($0.message ?? "")" }.joined(separator: ", ")
                throw ICSExporter.ExportError.validationFailed(errors)
            }
            try icsContent.write(to: url, atomically: true, encoding: .utf8)
            
        case .failure(let error):
            throw ICSExporter.ExportError.validationFailed(error.localizedDescription)
        }
    }
    
    private func escapeString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
    
    private func formatDate(_ date: Date, isAllDay: Bool) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = isAllDay ? "yyyyMMdd" : "yyyyMMdd'T'HHmmss'Z'"
        return dateFormatter.string(from: date)
    }
    
    enum ExportError: Error {
        case invalidContent
        case validationFailed(String)
    }
}

import SwiftUI
import UniformTypeIdentifiers

struct ICSImportView: View {
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var importResult: ImportResult?
    @State private var showingSuccessMessage = false
    @State private var isImporting = false
    @State private var validationResults: [ValidationResult] = []
    
    struct ValidationResult: Identifiable {
        let id = UUID()
        let type: ValidationType
        let passed: Bool
        let message: String
        
        static func create(_ type: ValidationType, passed: Bool) -> ValidationResult {
            ValidationResult(
                type: type,
                passed: passed,
                message: passed ? type.successMessage : type.failureMessage
            )
        }
    }
    
    enum ValidationType {
        case structure
        case version
        case recurrenceRule
        case duration
        case attachments
        case alarms
        case timezones
        case requiredFields
        
        var title: String {
            switch self {
            case .structure: return String(localized: "VCALENDAR Struktur")
            case .version: return String(localized: "iCalendar Version")
            case .recurrenceRule: return String(localized: "Wiederholungsregeln")
            case .duration: return String(localized: "Dauer/Endzeit")
            case .attachments: return String(localized: "Anhänge")
            case .alarms: return String(localized: "Erinnerungen")
            case .timezones: return String(localized: "Zeitzonen")
            case .requiredFields: return String(localized: "Pflichtfelder")
            }
        }
        
        var successMessage: String {
            switch self {
            case .structure: return String(localized: "Gültige VCALENDAR Struktur")
            case .version: return String(localized: "Unterstützte iCalendar Version")
            case .recurrenceRule: return String(localized: "Gültige Wiederholungsregeln")
            case .duration: return String(localized: "Gültige Dauer/Endzeit")
            case .attachments: return String(localized: "Gültige Anhänge")
            case .alarms: return String(localized: "Gültige Erinnerungen")
            case .timezones: return String(localized: "Gültige Zeitzonen")
            case .requiredFields: return String(localized: "Alle Pflichtfelder vorhanden")
            }
        }
        
        var failureMessage: String {
            switch self {
            case .structure: return String(localized: "Ungültige VCALENDAR Struktur")
            case .version: return String(localized: "Nicht unterstützte Version")
            case .recurrenceRule: return String(localized: "Ungültige Wiederholungsregeln")
            case .duration: return String(localized: "Ungültige Dauer/Endzeit")
            case .attachments: return String(localized: "Ungültige Anhänge")
            case .alarms: return String(localized: "Ungültige Erinnerungen")
            case .timezones: return String(localized: "Ungültige Zeitzonen")
            case .requiredFields: return String(localized: "Fehlende Pflichtfelder")
            }
        }
    }
    
    struct ImportResult {
        let success: Bool
        let events: [ICSEvent]
        let message: String
    }
    
    struct ImportFeatureItem: View {
        let text: String
        
        var body: some View {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(text)
                    .font(.subheadline)
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "ICS-Datei importieren"))
                        .font(.headline)
                    
                    Text(String(localized: "Importieren Sie einen Termin aus einer ICS-Datei in Ihre Terminliste."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ImportFeatureItem(text: String(localized: "Unterstützt Outlook, Apple Calendar und Google Calendar"))
                        ImportFeatureItem(text: String(localized: "Importiert Titel, Datum, Uhrzeit und Ort"))
                        ImportFeatureItem(text: String(localized: "Erkennt ganztägige Termine"))
                        ImportFeatureItem(text: String(localized: "Übernimmt Notizen und Beschreibungen"))
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section {
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.blue)
                        Text(String(localized: "ICS-Datei auswählen"))
                    }
                }
                .disabled(isImporting)
            }
            
            if let result = importResult {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.success ? .green : .red)
                            Text(result.message)
                                .font(.headline)
                        }
                        
                        if !result.events.isEmpty {
                            ForEach(result.events, id: \.id) { event in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(event.title)
                                        .font(.headline)
                                    Text(event.formattedDate)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    if let location = event.location {
                                        Text(location)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            
            if !validationResults.isEmpty {
                Section {
                    ForEach(validationResults, id: \.id) { result in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(result.type.title)
                                .font(.headline)
                            Text(result.message)
                                .font(.subheadline)
                                .foregroundColor(result.passed ? .green : .red)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "ICS importieren"))
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "ics")!],
            allowsMultipleSelection: false
        ) { result in
            isImporting = true
            
            switch result {
            case .success(let urls):
                guard let selectedFileURL = urls.first else { return }
                
                guard selectedFileURL.startAccessingSecurityScopedResource() else {
                    importResult = ImportResult(
                        success: false,
                        events: [],
                        message: String(localized: "Keine Berechtigung zum Lesen der Datei")
                    )
                    isImporting = false
                    return
                }
                
                defer {
                    selectedFileURL.stopAccessingSecurityScopedResource()
                }
                
                processICSFile(selectedFileURL)
            case .failure(let error):
                importResult = ImportResult(
                    success: false,
                    events: [],
                    message: String(localized: "Fehler beim Auswählen der Datei: \(error.localizedDescription)")
                )
            }
            
            isImporting = false
        }
        .overlay {
            if isImporting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(String(localized: "Importiere Termin..."))
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    }
            }
        }
    }
    
    private func processICSFile(_ url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            
            // Validiere die ICS-Datei im Hintergrund
            let validationResult = ICSValidator.validate(content)
            switch validationResult {
            case .success(let checks):
                // Prüfe ob alle Validierungen erfolgreich waren
                let isValid = checks.allSatisfy { $0.passed }
                if isValid {
                    // Fahre mit dem Import fort
                    try processValidICSContent(content)
                } else {
                    // Zeige Fehlermeldung
                    let failedChecks = checks.filter { !$0.passed }
                    let errorMessages = failedChecks.compactMap { $0.message }
                    importResult = ImportResult(
                        success: false,
                        events: [],
                        message: errorMessages.joined(separator: "\n")
                    )
                }
            case .failure(let error):
                importResult = ImportResult(
                    success: false,
                    events: [],
                    message: error.localizedDescription
                )
            }
        } catch {
            importResult = ImportResult(
                success: false,
                events: [],
                message: error.localizedDescription
            )
        }
    }
    
    private func processValidICSContent(_ content: String) throws {
        let lines = content.components(separatedBy: .newlines)
        
        // Validiere grundlegende VCALENDAR-Struktur
        guard let firstLine = lines.first?.trimmingCharacters(in: .whitespaces),
              let lastLine = lines.last?.trimmingCharacters(in: .whitespaces),
              firstLine == "BEGIN:VCALENDAR",
              lastLine == "END:VCALENDAR" else {
            validationResults.append(.create(.structure, passed: false))
            return
        }
        validationResults.append(.create(.structure, passed: true))
        
        // Validiere Version
        guard lines.contains(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("VERSION:2.0") }) else {
            validationResults.append(.create(.version, passed: false))
            return
        }
        validationResults.append(.create(.version, passed: true))
        
        var currentEvent: [String: String] = [:]
        var currentAlarm: [String: String]?
        var isInEvent = false
        var isInAlarm = false
        var seenUIDs = Set<String>()
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine == "BEGIN:VEVENT" {
                isInEvent = true
                currentEvent = [:]
            } else if trimmedLine == "END:VEVENT" {
                if let event = createEventFromProperties(currentEvent) {
                    // Überprüfe UID auf Eindeutigkeit
                    if let uid = currentEvent["UID"] {
                        if !seenUIDs.contains(uid) {
                            seenUIDs.insert(uid)
                            viewModel.addEvent(event)
                        }
                    } else {
                        // Wenn keine UID vorhanden ist, generiere eine
                        viewModel.addEvent(event)
                    }
                }
                isInEvent = false
            } else if trimmedLine == "BEGIN:VALARM" {
                isInAlarm = true
                currentAlarm = [:]
            } else if trimmedLine == "END:VALARM" {
                if let alarm = currentAlarm,
                   validateAlarm(alarm) {
                    currentEvent["VALARM"] = "VALID"
                }
                isInAlarm = false
                currentAlarm = nil
            } else if isInAlarm {
                if let colonIndex = trimmedLine.firstIndex(of: ":") {
                    let key = String(trimmedLine[..<colonIndex])
                    let value = String(trimmedLine[trimmedLine.index(after: colonIndex)...])
                    currentAlarm?[key] = value
                }
            } else if isInEvent {
                if let colonIndex = trimmedLine.firstIndex(of: ":") {
                    let key = String(trimmedLine[..<colonIndex])
                    var value = String(trimmedLine[trimmedLine.index(after: colonIndex)...])
                    
                    if key.contains(";") {
                        let components = key.components(separatedBy: ";")
                        let mainKey = components[0]
                        
                        // Verarbeite Parameter
                        for param in components.dropFirst() {
                            let paramComponents = param.components(separatedBy: "=")
                            if paramComponents.count == 2 {
                                currentEvent["\(mainKey)_\(paramComponents[0])"] = paramComponents[1]
                            }
                        }
                        
                        // Speichere Hauptwert
                        currentEvent[mainKey] = value
                    } else {
                        // Verarbeite Escape-Sequenzen
                        value = value.replacingOccurrences(of: "\\,", with: ",")
                            .replacingOccurrences(of: "\\;", with: ";")
                            .replacingOccurrences(of: "\\n", with: "\n")
                            .replacingOccurrences(of: "\\N", with: "\n")
                        
                        currentEvent[key] = value
                    }
                }
            }
        }
        
        importResult = ImportResult(
            success: true,
            events: viewModel.events,
            message: String(localized: "\(viewModel.events.count) Termin(e) erfolgreich importiert")
        )
        
        // Automatisch schließen nach erfolgreichem Import
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    private func validateAlarm(_ alarm: [String: String]) -> Bool {
        // Validiere VALARM nach RFC 5545
        guard let action = alarm["ACTION"],
              ["AUDIO", "DISPLAY", "EMAIL"].contains(action),
              let trigger = alarm["TRIGGER"] else {
            validationResults.append(.create(.alarms, passed: false))
            return false
        }
        
        // Validiere TRIGGER Format
        if trigger.hasPrefix("P") {
            // Duration format (e.g., PT15M)
            let durationPattern = #"^(-)?P(\d+W)?(\d+D)?(T(\d+H)?(\d+M)?(\d+S)?)?$"#
            guard trigger.range(of: durationPattern, options: .regularExpression) != nil else {
                validationResults.append(.create(.alarms, passed: false))
                return false
            }
        } else if trigger.hasPrefix("VALUE=DATE-TIME:") {
            // Absolute time format
            let dateStr = String(trigger.dropFirst("VALUE=DATE-TIME:".count))
            guard parseICSDate(dateStr, isAllDay: false, timezone: nil) != nil else {
                validationResults.append(.create(.alarms, passed: false))
                return false
            }
        } else {
            validationResults.append(.create(.alarms, passed: false))
            return false
        }
        
        validationResults.append(.create(.alarms, passed: true))
        return true
    }
    
    private func validateAttachment(_ attach: String, params: [String: String]) -> Bool {
        // Validiere ATTACH nach RFC 5545
        if let fmttype = params["FMTTYPE"] {
            // Prüfe MIME-Type Format
            let mimePattern = #"^[a-zA-Z0-9]+/[a-zA-Z0-9\-\+\.]+$"#
            guard fmttype.range(of: mimePattern, options: .regularExpression) != nil else {
                validationResults.append(.create(.attachments, passed: false))
                return false
            }
        }
        
        if attach.hasPrefix("data:") {
            // Inline-Daten
            guard attach.contains(";base64,") else {
                validationResults.append(.create(.attachments, passed: false))
                return false
            }
        } else {
            // URI
            guard URL(string: attach) != nil else {
                validationResults.append(.create(.attachments, passed: false))
                return false
            }
        }
        
        validationResults.append(.create(.attachments, passed: true))
        return true
    }
    
    private func validateRecurrenceRule(_ rrule: String) -> Bool {
        let components = rrule.components(separatedBy: ";")
        var hasFreq = false
        
        for component in components {
            let parts = component.components(separatedBy: "=")
            guard parts.count == 2 else {
                validationResults.append(.create(.recurrenceRule, passed: false))
                return false
            }
            
            let name = parts[0].uppercased()
            let value = parts[1].uppercased()
            
            switch name {
            case "FREQ":
                hasFreq = true
                guard ["SECONDLY", "MINUTELY", "HOURLY", "DAILY", "WEEKLY", "MONTHLY", "YEARLY"].contains(value) else {
                    validationResults.append(.create(.recurrenceRule, passed: false))
                    return false
                }
            case "INTERVAL":
                guard Int(value) != nil else {
                    validationResults.append(.create(.recurrenceRule, passed: false))
                    return false
                }
            case "UNTIL":
                guard parseICSDate(value, isAllDay: false, timezone: nil) != nil else {
                    validationResults.append(.create(.recurrenceRule, passed: false))
                    return false
                }
            case "COUNT":
                guard Int(value) != nil else {
                    validationResults.append(.create(.recurrenceRule, passed: false))
                    return false
                }
            case "BYSECOND", "BYMINUTE", "BYHOUR":
                let numbers = value.components(separatedBy: ",")
                for num in numbers {
                    guard let n = Int(num), n >= 0, n <= 59 else {
                        validationResults.append(.create(.recurrenceRule, passed: false))
                        return false
                    }
                }
            case "BYDAY":
                let days = value.components(separatedBy: ",")
                let validDays = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                for day in days {
                    let dayOnly = day.replacingOccurrences(of: "[+-]\\d+", with: "", options: .regularExpression)
                    guard validDays.contains(dayOnly) else {
                        validationResults.append(.create(.recurrenceRule, passed: false))
                        return false
                    }
                }
            case "BYMONTHDAY":
                let days = value.components(separatedBy: ",")
                for day in days {
                    guard let n = Int(day), abs(n) <= 31, n != 0 else {
                        validationResults.append(.create(.recurrenceRule, passed: false))
                        return false
                    }
                }
            case "BYMONTH":
                let months = value.components(separatedBy: ",")
                for month in months {
                    guard let n = Int(month), n >= 1, n <= 12 else {
                        validationResults.append(.create(.recurrenceRule, passed: false))
                        return false
                    }
                }
            default:
                break
            }
        }
        
        guard hasFreq else {
            validationResults.append(.create(.recurrenceRule, passed: false))
            return false
        }
        
        validationResults.append(.create(.recurrenceRule, passed: true))
        return true
    }
    
    private func createEventFromProperties(_ properties: [String: String]) -> ICSEvent? {
        // Validiere erforderliche Felder
        guard let title = properties["SUMMARY"],
              !title.isEmpty else {
            validationResults.append(.create(.requiredFields, passed: false))
            return nil
        }
        
        // Validiere DTSTAMP
        guard properties["DTSTAMP"] != nil else {
            validationResults.append(.create(.requiredFields, passed: false))
            return nil
        }
        
        // Validiere RRULE wenn vorhanden
        if let rrule = properties["RRULE"] {
            guard validateRecurrenceRule(rrule) else {
                return nil
            }
        }
        
        // Validiere ATTACH wenn vorhanden
        if let attach = properties["ATTACH"] {
            var params: [String: String] = [:]
            if let fmttype = properties["ATTACH_FMTTYPE"] {
                params["FMTTYPE"] = fmttype
            }
            guard validateAttachment(attach, params: params) else {
                return nil
            }
        }
        
        var startDate: Date?
        var endDate: Date?
        var isAllDay = false
        var timezone: TimeZone?
        
        // Verarbeite Zeitzone
        if let tzid = properties["DTSTART_TZID"] {
            timezone = TimeZone(identifier: tzid)
            validationResults.append(.create(.timezones, passed: timezone != nil))
        }
        
        if let dtstart = properties["DTSTART"] {
            if dtstart.contains("VALUE=DATE:") {
                isAllDay = true
                let dateStr = dtstart.components(separatedBy: ":").last ?? ""
                startDate = parseICSDate(dateStr, isAllDay: true, timezone: timezone)
            } else {
                let dateStr = dtstart.components(separatedBy: ":").last ?? ""
                startDate = parseICSDate(dateStr, isAllDay: false, timezone: timezone)
            }
        }
        
        // Verarbeite DURATION oder DTEND
        if let duration = properties["DURATION"] {
            // Parse duration format (e.g., PT1H30M)
            if let start = startDate {
                let components = parseDuration(duration)
                endDate = Calendar.current.date(byAdding: components, to: start)
            }
        } else if let dtend = properties["DTEND"] {
            if dtend.contains("VALUE=DATE:") {
                let dateStr = dtend.components(separatedBy: ":").last ?? ""
                endDate = parseICSDate(dateStr, isAllDay: true, timezone: timezone)
            } else {
                let dateStr = dtend.components(separatedBy: ":").last ?? ""
                endDate = parseICSDate(dateStr, isAllDay: false, timezone: timezone)
            }
        }
        
        // Validiere Datum-Logik
        guard let start = startDate,
              let end = endDate,
              end >= start else {
            validationResults.append(.create(.duration, passed: false))
            return nil
        }
        
        validationResults.append(.create(.duration, passed: true))
        
        return ICSEvent(
            title: title,
            startDate: start,
            endDate: end,
            isAllDay: isAllDay,
            location: properties["LOCATION"],
            notes: properties["DESCRIPTION"]
        )
    }
    
    private func parseDuration(_ duration: String) -> DateComponents {
        var components = DateComponents()
        
        // Entferne P am Anfang
        var remaining = duration.dropFirst()
        
        // Prüfe auf negative Dauer
        let isNegative = duration.hasPrefix("-")
        if isNegative {
            remaining = remaining.dropFirst()
        }
        
        // Parse Wochen
        if let wIndex = remaining.firstIndex(of: "W") {
            if let weeks = Int(remaining[..<wIndex]) {
                components.day = (isNegative ? -1 : 1) * (weeks * 7)
            }
            return components
        }
        
        // Parse Tage
        if let dIndex = remaining.firstIndex(of: "D") {
            if let days = Int(remaining[..<dIndex]) {
                components.day = (isNegative ? -1 : 1) * days
            }
            remaining = remaining[remaining.index(after: dIndex)...]
        }
        
        // Parse Zeit (nach T)
        if remaining.first == "T" {
            remaining = remaining.dropFirst()
            
            // Parse Stunden
            if let hIndex = remaining.firstIndex(of: "H") {
                if let hours = Int(remaining[..<hIndex]) {
                    components.hour = (isNegative ? -1 : 1) * hours
                }
                remaining = remaining[remaining.index(after: hIndex)...]
            }
            
            // Parse Minuten
            if let mIndex = remaining.firstIndex(of: "M") {
                if let minutes = Int(remaining[..<mIndex]) {
                    components.minute = (isNegative ? -1 : 1) * minutes
                }
                remaining = remaining[remaining.index(after: mIndex)...]
            }
            
            // Parse Sekunden
            if let sIndex = remaining.firstIndex(of: "S") {
                if let seconds = Int(remaining[..<sIndex]) {
                    components.second = (isNegative ? -1 : 1) * seconds
                }
            }
        }
        
        return components
    }
    
    private func parseICSDate(_ dateString: String, isAllDay: Bool, timezone: TimeZone?) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let tz = timezone {
            formatter.timeZone = tz
        } else {
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
        }
        
        if isAllDay {
            formatter.dateFormat = "yyyyMMdd"
        } else {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        }
        
        return formatter.date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

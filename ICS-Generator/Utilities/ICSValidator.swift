import Foundation

public struct ValidationCheck: Identifiable {
    public let id = UUID()
    public let type: String
    public let description: String
    public let passed: Bool
    public let message: String?
    public let category: ValidationCategory
    
    public init(type: String, description: String, passed: Bool, message: String? = nil, category: ValidationCategory = .allgemein) {
        self.type = type
        self.description = description
        self.passed = passed
        self.message = message
        self.category = category
    }
}

public enum ValidationCategory: String {
    case allgemein = "Allgemein"
    case struktur = "Struktur"
    case inhalt = "Inhalt"
    case format = "Format"
    case teilnehmer = "Teilnehmer"
    case erinnerungen = "Erinnerungen"
}

public class ICSValidator {
    public enum ValidationError: LocalizedError {
        case invalidFormat(String)
        case missingRequiredProperty(String)
        case invalidPropertyValue(String)
        case invalidEncoding(String)
        case invalidStructure(String)
        
        public var errorDescription: String? {
            switch self {
            case .invalidFormat(let message): return message
            case .missingRequiredProperty(let property): return "Erforderliche Eigenschaft fehlt: \(property)"
            case .invalidPropertyValue(let message): return message
            case .invalidEncoding(let message): return "Ungültige Zeichenkodierung: \(message)"
            case .invalidStructure(let message): return "Ungültige Struktur: \(message)"
            }
        }
    }
    
    public static func validate(_ content: String) -> Result<[ValidationCheck], Error> {
        var checks: [ValidationCheck] = []
        
        // Prüfe Zeichenkodierung
        let encodingValid = validateEncoding(content)
        checks.append(ValidationCheck(
            type: "Kodierung",
            description: "Zeichenkodierung",
            passed: encodingValid.0,
            message: encodingValid.1,
            category: .format
        ))
        
        // Prüfe Zeilenlänge und Faltung
        let lineWrappingValid = validateLineWrapping(content)
        checks.append(ValidationCheck(
            type: "Zeilenlänge",
            description: "Zeilenlänge und -faltung",
            passed: lineWrappingValid.0,
            message: lineWrappingValid.1,
            category: .format
        ))
        
        // Prüfe grundlegende Struktur
        let hasVCalendar = content.contains("BEGIN:VCALENDAR") && content.contains("END:VCALENDAR")
        checks.append(ValidationCheck(
            type: "Struktur",
            description: "Grundlegende iCalendar-Struktur",
            passed: hasVCalendar,
            message: hasVCalendar ? "Die Datei enthält eine gültige iCalendar-Struktur" : "Die Datei muss mit BEGIN:VCALENDAR beginnen und mit END:VCALENDAR enden",
            category: .struktur
        ))
        
        guard hasVCalendar else {
            return .success(checks)
        }
        
        // Prüfe Verschachtelung
        let nestingValid = validateNesting(content)
        checks.append(ValidationCheck(
            type: "Verschachtelung",
            description: "Komponenten-Verschachtelung",
            passed: nestingValid.0,
            message: nestingValid.1,
            category: .struktur
        ))
        
        // Prüfe Version
        let hasVersion = content.contains("VERSION:2.0")
        checks.append(ValidationCheck(
            type: "Version",
            description: "iCalendar Version",
            passed: hasVersion,
            message: hasVersion ? "Version 2.0 gefunden" : "Die Version 2.0 ist erforderlich",
            category: .allgemein
        ))
        
        // Prüfe VEVENT
        let hasEvent = content.contains("BEGIN:VEVENT") && content.contains("END:VEVENT")
        checks.append(ValidationCheck(
            type: "Event",
            description: "Kalenderereignis",
            passed: hasEvent,
            message: hasEvent ? "Mindestens ein gültiges Ereignis gefunden" : "Mindestens ein Event (VEVENT) ist erforderlich",
            category: .struktur
        ))
        
        // Prüfe Pflichtfelder in Events
        let eventCheck = validateEventRequiredFields(content)
        checks.append(ValidationCheck(
            type: "Pflichtfelder",
            description: "Erforderliche Event-Eigenschaften",
            passed: eventCheck.0,
            message: eventCheck.1,
            category: .inhalt
        ))
        
        // Prüfe RRULE
        if content.contains("RRULE:") {
            let rruleValid = validateRRule(content)
            checks.append(ValidationCheck(
                type: "Wiederholung",
                description: "Wiederholungsregel (RRULE)",
                passed: rruleValid.0,
                message: rruleValid.1,
                category: .inhalt
            ))
        }
        
        // Prüfe DURATION
        if content.contains("DURATION:") {
            let durationValid = validateDuration(content)
            checks.append(ValidationCheck(
                type: "Dauer",
                description: "Ereignisdauer",
                passed: durationValid.0,
                message: durationValid.1,
                category: .inhalt
            ))
        }
        
        // Prüfe ATTACH
        if content.contains("ATTACH") {
            let attachValid = validateAttachment(content)
            checks.append(ValidationCheck(
                type: "Anhänge",
                description: "Dateianhänge",
                passed: attachValid.0,
                message: attachValid.1,
                category: .inhalt
            ))
        }
        
        // Prüfe VALARM
        if content.contains("BEGIN:VALARM") {
            let alarmValid = validateAlarm(content)
            checks.append(ValidationCheck(
                type: "Erinnerungen",
                description: "Ereigniserinnerungen",
                passed: alarmValid.0,
                message: alarmValid.1,
                category: .erinnerungen
            ))
        }
        
        // Prüfe Datumsformate
        let dateCheck = validateDateFormats(content)
        checks.append(ValidationCheck(
            type: "Datum",
            description: "Datumsformate",
            passed: dateCheck.0,
            message: dateCheck.1,
            category: .inhalt
        ))
        
        // Prüfe Zeitzone
        if content.contains("TZID") {
            let timezoneValid = validateTimezone(content)
            checks.append(ValidationCheck(
                type: "Zeitzone",
                description: "Zeitzonen-Definition",
                passed: timezoneValid.0,
                message: timezoneValid.1,
                category: .inhalt
            ))
        }
        
        // Prüfe Kategorien
        if content.contains("CATEGORIES:") {
            let categoriesValid = validateCategories(content)
            checks.append(ValidationCheck(
                type: "Kategorien",
                description: "Event-Kategorien",
                passed: categoriesValid.0,
                message: categoriesValid.1,
                category: .inhalt
            ))
        }
        
        // Prüfe Priorität
        if content.contains("PRIORITY:") {
            let priorityValid = validatePriority(content)
            checks.append(ValidationCheck(
                type: "Priorität",
                description: "Event-Priorität",
                passed: priorityValid.0,
                message: priorityValid.1,
                category: .inhalt
            ))
        }
        
        // Prüfe Status
        if content.contains("STATUS:") {
            let statusValid = validateStatus(content)
            checks.append(ValidationCheck(
                type: "Status",
                description: "Event-Status",
                passed: statusValid.0,
                message: statusValid.1,
                category: .inhalt
            ))
        }
        
        // Prüfe Teilnehmer
        if content.contains("ATTENDEE:") {
            let attendeeValid = validateAttendees(content)
            checks.append(ValidationCheck(
                type: "Teilnehmer",
                description: "Event-Teilnehmer",
                passed: attendeeValid.0,
                message: attendeeValid.1,
                category: .teilnehmer
            ))
        }
        
        return .success(checks)
    }
    
    private static func validateEventRequiredFields(_ content: String) -> (Bool, String?) {
        let requiredFields = ["SUMMARY", "DTSTART"]
        var missingFields: [String] = []
        
        for field in requiredFields {
            if !content.contains("\(field):") {
                missingFields.append(field)
            }
        }
        
        if missingFields.isEmpty {
            return (true, "Alle erforderlichen Felder sind vorhanden")
        } else {
            return (false, "Fehlende Pflichtfelder: \(missingFields.joined(separator: ", "))")
        }
    }
    
    private static func validateRRule(_ content: String) -> (Bool, String?) {
        let rrulePattern = "RRULE:[^\\r\\n]+"
        guard let regex = try? NSRegularExpression(pattern: rrulePattern) else {
            return (false, "Fehler beim Validieren der Wiederholungsregel")
        }
        
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, range: range)
        
        for match in matches {
            if let range = Range(match.range, in: content) {
                let rrule = content[range]
                if !rrule.contains("FREQ=") {
                    return (false, "FREQ ist ein erforderlicher Parameter für RRULE")
                }
                
                // Prüfe gültige FREQ-Werte
                let validFreqs = ["SECONDLY", "MINUTELY", "HOURLY", "DAILY", "WEEKLY", "MONTHLY", "YEARLY"]
                let freqValid = validFreqs.contains { rrule.contains("FREQ=\($0)") }
                if !freqValid {
                    return (false, "Ungültiger FREQ-Wert. Erlaubt sind: \(validFreqs.joined(separator: ", "))")
                }
            }
        }
        
        return (true, "Wiederholungsregel ist gültig")
    }
    
    private static func validateDuration(_ content: String) -> (Bool, String?) {
        let durationPattern = "DURATION:P(?:[0-9]+[WDHMS])+[^\\r\\n]*"
        guard let regex = try? NSRegularExpression(pattern: durationPattern) else {
            return (false, "Fehler beim Validieren der Dauer")
        }
        
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, range: range)
        
        if matches.isEmpty {
            return (false, "Ungültiges DURATION Format")
        }
        
        return (true, "Dauer ist im korrekten Format")
    }
    
    private static func validateAttachment(_ content: String) -> (Bool, String?) {
        let attachPattern = "ATTACH[^\\r\\n]+"
        guard let regex = try? NSRegularExpression(pattern: attachPattern) else {
            return (false, "Fehler beim Validieren der Anhänge")
        }
        
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, range: range)
        var validCount = 0
        
        for match in matches {
            if let range = Range(match.range, in: content) {
                let attach = String(content[range])
                if attach.contains("http") || attach.contains("data:") {
                    validCount += 1
                } else {
                    return (false, "Anhänge müssen entweder eine URL oder Base64-kodierte Daten sein")
                }
            }
        }
        
        return (true, "\(validCount) gültige Anhänge gefunden")
    }
    
    private static func validateAlarm(_ content: String) -> (Bool, String?) {
        let lines = content.components(separatedBy: .newlines)
        var inAlarm = false
        var hasAction = false
        var hasTrigger = false
        var alarmCount = 0
        let validActions = ["AUDIO", "DISPLAY", "EMAIL"]
        
        for line in lines {
            if line.contains("BEGIN:VALARM") {
                inAlarm = true
                hasAction = false
                hasTrigger = false
                alarmCount += 1
                continue
            }
            
            if line.contains("END:VALARM") {
                if !hasAction || !hasTrigger {
                    return (false, "VALARM erfordert ACTION und TRIGGER")
                }
                inAlarm = false
                continue
            }
            
            if inAlarm {
                if line.contains("ACTION:") {
                    hasAction = validActions.contains { line.contains("ACTION:\($0)") }
                    if !hasAction {
                        return (false, "Ungültige ACTION. Erlaubt sind: \(validActions.joined(separator: ", "))")
                    }
                }
                if line.contains("TRIGGER") { hasTrigger = true }
            }
        }
        
        return (true, "\(alarmCount) gültige Erinnerung(en) gefunden")
    }
    
    private static func validateDateFormats(_ content: String) -> (Bool, String?) {
        let datePattern = "(DTSTART|DTEND|DUE|COMPLETED):[0-9]{8}(T[0-9]{6}Z?)?"
        guard let regex = try? NSRegularExpression(pattern: datePattern) else {
            return (false, "Fehler beim Validieren der Datumsformate")
        }
        
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, range: range)
        
        if matches.isEmpty {
            return (false, "Keine gültigen Datumsformate gefunden")
        }
        
        return (true, "\(matches.count) gültige Datumsangaben gefunden")
    }
    
    private static func validateTimezone(_ content: String) -> (Bool, String?) {
        let lines = content.components(separatedBy: .newlines)
        var hasVTimezone = false
        var tzidCount = 0
        
        for line in lines {
            if line.contains("BEGIN:VTIMEZONE") {
                hasVTimezone = true
            }
            if line.contains("TZID:") {
                let tzid = line.components(separatedBy: "TZID:")[1]
                if TimeZone(identifier: tzid) != nil {
                    tzidCount += 1
                } else {
                    return (false, "Ungültige Zeitzone: \(tzid)")
                }
            }
        }
        
        if tzidCount > 0 && !hasVTimezone {
            return (false, "TZID verwendet aber keine VTIMEZONE Definition gefunden")
        }
        
        return (true, "\(tzidCount) gültige Zeitzonen gefunden")
    }
    
    private static func validateCategories(_ content: String) -> (Bool, String?) {
        let categoryPattern = "CATEGORIES:([^\\r\\n]+)"
        guard let regex = try? NSRegularExpression(pattern: categoryPattern) else {
            return (false, "Fehler beim Validieren der Kategorien")
        }
        
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, range: range)
        var categoryCount = 0
        
        for match in matches {
            if let range = Range(match.range, in: content) {
                let categories = content[range].components(separatedBy: ",")
                categoryCount += categories.count
            }
        }
        
        return (true, "\(categoryCount) Kategorien gefunden")
    }
    
    private static func validatePriority(_ content: String) -> (Bool, String?) {
        let priorityPattern = "PRIORITY:([0-9])"
        guard let regex = try? NSRegularExpression(pattern: priorityPattern) else {
            return (false, "Fehler beim Validieren der Priorität")
        }
        
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, range: range)
        
        for match in matches {
            if let range = Range(match.range, in: content),
               let priorityStr = content[range].components(separatedBy: ":").last,
               let priority = Int(priorityStr) {
                if priority < 0 || priority > 9 {
                    return (false, "Priorität muss zwischen 0 und 9 liegen")
                }
            }
        }
        
        return (true, "Priorität ist gültig")
    }
    
    private static func validateStatus(_ content: String) -> (Bool, String?) {
        let validStatus = ["TENTATIVE", "CONFIRMED", "CANCELLED"]
        let statusPattern = "STATUS:([^\\r\\n]+)"
        guard let regex = try? NSRegularExpression(pattern: statusPattern) else {
            return (false, "Fehler beim Validieren des Status")
        }
        
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, range: range)
        
        for match in matches {
            if let range = Range(match.range, in: content) {
                let status = content[range].components(separatedBy: ":")[1]
                if !validStatus.contains(status) {
                    return (false, "Ungültiger Status. Erlaubt sind: \(validStatus.joined(separator: ", "))")
                }
            }
        }
        
        return (true, "Status ist gültig")
    }
    
    private static func validateAttendees(_ content: String) -> (Bool, String?) {
        let attendeePattern = "ATTENDEE([^\\r\\n]+)"
        guard let regex = try? NSRegularExpression(pattern: attendeePattern) else {
            return (false, "Fehler beim Validieren der Teilnehmer")
        }
        
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, range: range)
        var attendeeCount = 0
        
        for match in matches {
            if let range = Range(match.range, in: content) {
                let attendee = String(content[range])
                if !attendee.contains("mailto:") {
                    return (false, "Teilnehmer müssen eine E-Mail-Adresse haben (mailto:)")
                }
                attendeeCount += 1
            }
        }
        
        return (true, "\(attendeeCount) gültige Teilnehmer gefunden")
    }
    
    private static func validateNesting(_ content: String) -> (Bool, String?) {
        let lines = content.components(separatedBy: .newlines)
        var stack: [String] = []
        var lineNumber = 0
        
        for line in lines {
            lineNumber += 1
            if line.hasPrefix("BEGIN:") {
                let component = line.components(separatedBy: "BEGIN:")[1]
                stack.append(component)
            } else if line.hasPrefix("END:") {
                let component = line.components(separatedBy: "END:")[1]
                if stack.isEmpty || stack.last != component {
                    return (false, "Fehlerhafte Verschachtelung in Zeile \(lineNumber): END:\(component)")
                }
                stack.removeLast()
            }
        }
        
        if !stack.isEmpty {
            return (false, "Nicht alle Komponenten wurden geschlossen: \(stack.joined(separator: ", "))")
        }
        
        return (true, "Verschachtelung ist korrekt")
    }
    
    private static func validateEncoding(_ content: String) -> (Bool, String?) {
        // Prüfe auf ungültige UTF-8 Zeichen
        if let data = content.data(using: .utf8),
           String(data: data, encoding: .utf8) != nil {
            
            // Prüfe auf problematische Zeichen
            let problematicCharacters = content.unicodeScalars.filter { scalar in
                // Erlaubt: ASCII druckbare Zeichen, Zeilenumbrüche und deutsche Umlaute
                let isASCIIPrintable = (32...126).contains(scalar.value)
                let isNewline = scalar.value == 10 || scalar.value == 13  // LF und CR
                let isGermanChar = "äöüÄÖÜß".unicodeScalars.contains(scalar)
                
                return !(isASCIIPrintable || isNewline || isGermanChar)
            }
            
            if problematicCharacters.isEmpty {
                return (true, "Zeichenkodierung ist gültig")
            } else {
                let invalidChars = String(String.UnicodeScalarView(problematicCharacters))
                return (false, "Die Datei enthält möglicherweise problematische Zeichen: \(invalidChars)")
            }
        }
        
        return (false, "Die Datei enthält ungültige UTF-8 Zeichen")
    }
    
    private static func validateLineWrapping(_ content: String) -> (Bool, String?) {
        let lines = content.components(separatedBy: .newlines)
        var longLines = 0
        var lineNumber = 0
        
        for line in lines {
            lineNumber += 1
            if line.count > 75 && !line.hasPrefix(" ") {
                longLines += 1
            }
        }
        
        if longLines > 0 {
            return (false, "\(longLines) Zeilen sind länger als 75 Zeichen und nicht korrekt gefaltet")
        }
        
        return (true, "Alle Zeilen sind korrekt gefaltet")
    }
}

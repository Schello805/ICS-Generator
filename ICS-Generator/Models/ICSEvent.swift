import Foundation

struct ICSEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var location: String?
    var notes: String?
    var url: String?
    var travelTime: Int
    var alert: AlertTime
    var recurrence: RecurrenceRule
    var customRecurrence: CustomRecurrence?
    var attachments: [Attachment]
    
    init(id: UUID = UUID(), 
         title: String, 
         startDate: Date, 
         endDate: Date,
         isAllDay: Bool = false,
         location: String? = nil, 
         notes: String? = nil,
         url: String? = nil,
         travelTime: Int = 0,
         alert: AlertTime = .fifteenMinutes,
         recurrence: RecurrenceRule = .none,
         customRecurrence: CustomRecurrence? = nil,
         attachments: [Attachment] = []) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.url = url
        self.travelTime = travelTime
        self.alert = alert
        self.recurrence = recurrence
        self.customRecurrence = customRecurrence
        self.attachments = attachments
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        
        if isAllDay {
            formatter.dateStyle = .medium
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                return formatter.string(from: startDate)
            } else {
                return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
            }
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                return "\(formatter.string(from: startDate)) - \(DateFormatter.timeOnly.string(from: endDate))"
            } else {
                return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
            }
        }
    }
    
    private func escapeString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
    
    private func foldLine(_ line: String) -> String {
        var result = ""
        var currentLine = line
        
        while currentLine.count > 75 {
            let index = currentLine.index(currentLine.startIndex, offsetBy: 75)
            result += currentLine[..<index] + "\r\n "
            currentLine = String(currentLine[index...])
        }
        result += currentLine
        return result
    }
    
    func toICSString() -> String {
        var components: [String] = []
        components.append("BEGIN:VCALENDAR")
        components.append("VERSION:2.0")
        components.append("PRODID:-//ICS Generator//DE")
        components.append("CALSCALE:GREGORIAN")
        components.append("METHOD:PUBLISH")
        components.append("BEGIN:VEVENT")
        
        // Required Properties
        components.append("UID:\(id.uuidString)")
        components.append("DTSTAMP:\(formatDate(Date()))")
        components.append("DTSTART\(isAllDay ? ";VALUE=DATE" : ""):\(formatDate(startDate, isAllDay: isAllDay))")
        components.append("DTEND\(isAllDay ? ";VALUE=DATE" : ""):\(formatDate(endDate, isAllDay: isAllDay))")
        components.append("SUMMARY:\(escapeString(title))")
        
        // Optional Properties
        if let location = location {
            components.append("LOCATION:\(escapeString(location))")
        }
        
        if let notes = notes {
            components.append("DESCRIPTION:\(escapeString(notes))")
        }
        
        if let url = url {
            components.append("URL:\(escapeString(url))")
        }
        
        // Alert
        if alert != .none {
            components.append("BEGIN:VALARM")
            components.append("ACTION:DISPLAY")
            components.append("DESCRIPTION:\(escapeString(title))")
            
            let trigger: String
            switch alert {
            case .none:
                trigger = ""
            case .atTime:
                trigger = "TRIGGER;VALUE=DATE-TIME:\(formatDate(startDate))"
            case .fiveMinutes:
                trigger = "TRIGGER:-PT5M"
            case .tenMinutes:
                trigger = "TRIGGER:-PT10M"
            case .fifteenMinutes:
                trigger = "TRIGGER:-PT15M"
            case .thirtyMinutes:
                trigger = "TRIGGER:-PT30M"
            case .oneHour:
                trigger = "TRIGGER:-PT1H"
            case .twoHours:
                trigger = "TRIGGER:-PT2H"
            case .oneDay:
                trigger = "TRIGGER:-P1D"
            case .twoDays:
                trigger = "TRIGGER:-P2D"
            case .oneWeek:
                trigger = "TRIGGER:-P1W"
            }
            if !trigger.isEmpty {
                components.append(trigger)
                components.append("END:VALARM")
            }
        }
        
        // Recurrence
        switch recurrence {
        case .none:
            break
        case .daily:
            components.append("RRULE:FREQ=DAILY")
        case .weekly:
            components.append("RRULE:FREQ=WEEKLY")
        case .monthly:
            components.append("RRULE:FREQ=MONTHLY")
        case .yearly:
            components.append("RRULE:FREQ=YEARLY")
        case .custom:
            if let custom = customRecurrence {
                components.append("RRULE:" + custom.toRRuleString())
            }
        }
        
        components.append("END:VEVENT")
        components.append("END:VCALENDAR")
        
        // Fold lines and join with CRLF
        return components.map { foldLine($0) }.joined(separator: "\r\n") + "\r\n"
    }
    
    private func formatDate(_ date: Date, isAllDay: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        if isAllDay {
            formatter.dateFormat = "yyyyMMdd"
        } else {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        }
        
        return formatter.string(from: date)
    }
    
    static func validate(icsString: String) -> ValidationResult {
        let requiredFields = ["BEGIN:VEVENT", "UID:", "DTSTAMP:", "SUMMARY:", "DTSTART:", "DTEND:", "END:VEVENT"]
        let lines = icsString.components(separatedBy: .newlines)
        
        // Überprüfe erforderliche Felder
        for field in requiredFields {
            if !lines.contains(where: { $0.hasPrefix(field) }) {
                return .invalid("Erforderliches Feld fehlt: \(field)")
            }
        }
        
        // Überprüfe Datum-Format
        for line in lines {
            if line.hasPrefix("DTSTART:") || line.hasPrefix("DTEND:") || line.hasPrefix("DTSTAMP:") {
                let dateString = String(line.split(separator: ":")[1])
                if !isValidICSDate(dateString) {
                    return .invalid("Ungültiges Datumsformat: \(dateString)")
                }
            }
        }
        
        return .valid
    }
    
    static func from(icsString: String) -> ICSEvent? {
        let validation = validate(icsString: icsString)
        guard validation.isValid else { return nil }
        
        var title = ""
        var startDate = Date()
        var endDate = Date()
        var isAllDay = false
        var location: String?
        var notes: String?
        var url: String?
        var alert: AlertTime = .none
        var recurrence: RecurrenceRule = .none
        var inAlarm = false
        var alarmTrigger: String?
        
        let lines = icsString.components(separatedBy: .newlines)
        for line in lines {
            if line == "BEGIN:VALARM" {
                inAlarm = true
            } else if line == "END:VALARM" {
                inAlarm = false
            } else if inAlarm && line.hasPrefix("TRIGGER:") {
                alarmTrigger = String(line.dropFirst(8))
            } else if line.hasPrefix("SUMMARY:") {
                title = String(line.dropFirst(8))
            } else if line.hasPrefix("DTSTART") {
                if line.contains("VALUE=DATE:") {
                    isAllDay = true
                    startDate = parseAllDayDate(String(line.split(separator: ":").last ?? "")) ?? Date()
                } else {
                    startDate = parseDate(String(line.split(separator: ":").last ?? "")) ?? Date()
                }
            } else if line.hasPrefix("DTEND") {
                if line.contains("VALUE=DATE:") {
                    endDate = parseAllDayDate(String(line.split(separator: ":").last ?? "")) ?? Date()
                } else {
                    endDate = parseDate(String(line.split(separator: ":").last ?? "")) ?? Date()
                }
            } else if line.hasPrefix("LOCATION:") {
                location = String(line.dropFirst(9))
            } else if line.hasPrefix("DESCRIPTION:") {
                notes = String(line.dropFirst(12))
            } else if line.hasPrefix("URL:") {
                url = String(line.dropFirst(4))
            } else if line.hasPrefix("RRULE:") {
                let rruleString = String(line.dropFirst(6))
                recurrence = RecurrenceRule.from(icsString: rruleString)
            }
        }
        
        if let trigger = alarmTrigger {
            switch trigger {
            case "-PT0M": alert = .atTime
            case "-PT5M": alert = .fiveMinutes
            case "-PT10M": alert = .tenMinutes
            case "-PT15M": alert = .fifteenMinutes
            case "-PT30M": alert = .thirtyMinutes
            case "-PT1H": alert = .oneHour
            case "-PT2H": alert = .twoHours
            case "-P1D": alert = .oneDay
            case "-P2D": alert = .twoDays
            case "-P1W": alert = .oneWeek
            default: alert = .none
            }
        }
        
        return ICSEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: location,
            notes: notes,
            url: url,
            travelTime: 0,
            alert: alert,
            recurrence: recurrence
        )
    }
    
    private static func isValidICSDate(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return dateFormatter.date(from: dateString) != nil
    }
    
    private static func parseDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return dateFormatter.date(from: dateString)
    }
    
    private static func parseAllDayDate(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.date(from: dateString)
    }
    
    func duplicated() -> ICSEvent {
        ICSEvent(
            id: UUID(),
            title: "Kopie von " + self.title,
            startDate: self.startDate,
            endDate: self.endDate,
            isAllDay: self.isAllDay,
            location: self.location,
            notes: self.notes,
            url: self.url,
            travelTime: self.travelTime,
            alert: self.alert,
            recurrence: self.recurrence,
            customRecurrence: self.customRecurrence,
            attachments: self.attachments
        )
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ICSEvent, rhs: ICSEvent) -> Bool {
        lhs.id == rhs.id
    }
    
    enum ValidationResult {
        case valid
        case invalid(String)
        
        var isValid: Bool {
            switch self {
            case .valid: return true
            case .invalid: return false
            }
        }
    }
    
    enum AlertTime: String, CaseIterable, Codable {
        case none = "none"
        case atTime = "at_time"
        case fiveMinutes = "5_minutes"
        case tenMinutes = "10_minutes"
        case fifteenMinutes = "15_minutes"
        case thirtyMinutes = "30_minutes"
        case oneHour = "1_hour"
        case twoHours = "2_hours"
        case oneDay = "1_day"
        case twoDays = "2_days"
        case oneWeek = "1_week"
        
        var triggerValue: String {
            switch self {
            case .none: return ""
            case .atTime: return "-PT0M"
            case .fiveMinutes: return "-PT5M"
            case .tenMinutes: return "-PT10M"
            case .fifteenMinutes: return "-PT15M"
            case .thirtyMinutes: return "-PT30M"
            case .oneHour: return "-PT1H"
            case .twoHours: return "-PT2H"
            case .oneDay: return "-P1D"
            case .twoDays: return "-P2D"
            case .oneWeek: return "-P1W"
            }
        }
        
        func toICSString() -> String {
            switch self {
            case .none: return ""
            case .atTime: return "-PT0M"
            case .fiveMinutes: return "-PT5M"
            case .tenMinutes: return "-PT10M"
            case .fifteenMinutes: return "-PT15M"
            case .thirtyMinutes: return "-PT30M"
            case .oneHour: return "-PT1H"
            case .twoHours: return "-PT2H"
            case .oneDay: return "-P1D"
            case .twoDays: return "-P2D"
            case .oneWeek: return "-P1W"
            }
        }
    }
    
    enum RecurrenceRule: String, Codable, CaseIterable {
        case none = "NONE"
        case daily = "DAILY"
        case weekly = "WEEKLY"
        case monthly = "MONTHLY"
        case yearly = "YEARLY"
        case custom = "CUSTOM"
        
        var localizedString: String {
            switch self {
            case .none: return "Keine"
            case .daily: return "Täglich"
            case .weekly: return "Wöchentlich"
            case .monthly: return "Monatlich"
            case .yearly: return "Jährlich"
            case .custom: return "Benutzerdefiniert"
            }
        }
        
        func toICSString(customRecurrence: CustomRecurrence?) -> String {
            switch self {
            case .none: return ""
            case .daily: return "FREQ=DAILY"
            case .weekly: return "FREQ=WEEKLY"
            case .monthly: return "FREQ=MONTHLY"
            case .yearly: return "FREQ=YEARLY"
            case .custom:
                if let custom = customRecurrence {
                    return custom.toRRuleString()
                } else {
                    return ""
                }
            }
        }
        
        static func from(icsString: String) -> RecurrenceRule {
            let components = icsString.components(separatedBy: "=")
            guard components.count >= 2,
                  components[0] == "FREQ" else {
                return .none
            }
            
            switch components[1] {
            case "DAILY": return .daily
            case "WEEKLY": return .weekly
            case "MONTHLY": return .monthly
            case "YEARLY": return .yearly
            default:
                if icsString.contains("BYDAY") || icsString.contains("BYMONTHDAY") {
                    return .custom
                }
                return .none
            }
        }
    }
    
    enum WeekDay: String, CaseIterable, Codable {
        case monday = "MO"
        case tuesday = "TU"
        case wednesday = "WE"
        case thursday = "TH"
        case friday = "FR"
        case saturday = "SA"
        case sunday = "SU"
        
        var localizedName: String {
            switch self {
            case .monday: return "Montag"
            case .tuesday: return "Dienstag"
            case .wednesday: return "Mittwoch"
            case .thursday: return "Donnerstag"
            case .friday: return "Freitag"
            case .saturday: return "Samstag"
            case .sunday: return "Sonntag"
            }
        }
    }
    
    struct Attachment: Identifiable, Codable {
        let id: UUID
        let fileName: String
        let data: Data
        let type: AttachmentType
        
        init(id: UUID = UUID(), fileName: String, data: Data, type: AttachmentType) {
            self.id = id
            self.fileName = fileName
            self.data = data
            self.type = type
        }
    }
    
    enum AttachmentType: String, Codable {
        case pdf = "application/pdf"
        case jpeg = "image/jpeg"
        case png = "image/png"
        case heic = "image/heic"
        
        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .jpeg: return "jpg"
            case .png: return "png"
            case .heic: return "heic"
            }
        }
        
        var iconName: String {
            switch self {
            case .pdf: return "doc.fill"
            case .jpeg, .png, .heic: return "photo.fill"
            }
        }
        
        static func from(mimeType: String) -> AttachmentType? {
            return AttachmentType(rawValue: mimeType)
        }
        
        static func from(utType: String) -> AttachmentType? {
            switch utType {
            case "com.adobe.pdf": return .pdf
            case "public.jpeg": return .jpeg
            case "public.png": return .png
            case "public.heic": return .heic
            default: return nil
            }
        }
    }
    
    struct CustomRecurrence: Codable {
        var frequency: RecurrenceRule
        var interval: Int
        var count: Int?
        var until: Date?
        var weekDays: Set<WeekDay>?
        
        func toRRuleString() -> String {
            var components = ["FREQ=\(frequency.rawValue)"]
            
            if interval > 1 {
                components.append("INTERVAL=\(interval)")
            }
            
            if let count = count {
                components.append("COUNT=\(count)")
            }
            
            if let until = until {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                components.append("UNTIL=\(formatter.string(from: until))")
            }
            
            if let weekDays = weekDays, !weekDays.isEmpty {
                let days = weekDays.map { $0.rawValue }.sorted().joined(separator: ",")
                components.append("BYDAY=\(days)")
            }
            
            return components.joined(separator: ";")
        }
    }
}

extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

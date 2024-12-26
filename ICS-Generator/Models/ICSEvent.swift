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
    var alert: AlertTime
    var secondAlert: AlertTime
    var travelTime: Int
    var recurrence: RecurrenceRule
    var customRecurrence: CustomRecurrence?
    var attachments: [Attachment]
    
    var isValid: Bool {
        !title.isEmpty && endDate >= startDate
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        location: String? = nil,
        notes: String? = nil,
        url: String? = nil,
        alert: AlertTime = .fifteenMinutes,
        secondAlert: AlertTime = .none,
        travelTime: Int = 0,
        recurrence: RecurrenceRule = .none,
        customRecurrence: CustomRecurrence? = nil,
        attachments: [Attachment] = []
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.url = url
        self.alert = alert
        self.secondAlert = secondAlert
        self.travelTime = travelTime
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
        
        if alert != .none {
            components.append("BEGIN:VALARM")
            components.append("ACTION:DISPLAY")
            components.append("DESCRIPTION:Hinweis")
            components.append("TRIGGER:\(alert.triggerValue)")
            components.append("END:VALARM")
        }
        
        if secondAlert != .none {
            components.append("BEGIN:VALARM")
            components.append("ACTION:DISPLAY")
            components.append("DESCRIPTION:2. Hinweis")
            components.append("TRIGGER:\(secondAlert.triggerValue)")
            components.append("END:VALARM")
        }
        
        if recurrence != .none {
            components.append("RRULE:\(recurrence.toICSString(customRecurrence: customRecurrence))")
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
        var startDate: Date?
        var endDate: Date?
        var isAllDay = false
        var location: String?
        var notes: String?
        var url: String?
        var alert: AlertTime = .none
        var secondAlert: AlertTime = .none
        var inAlarm = false
        var alarmTrigger: String?
        var isInSecondAlarm = false
        var recurrence: RecurrenceRule = .none
        var customRecurrence: CustomRecurrence?
        
        let lines = icsString.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("BEGIN:VALARM") {
                inAlarm = true
            } else if line.hasPrefix("END:VALARM") {
                if let trigger = alarmTrigger {
                    let alertTime = AlertTime.from(triggerString: trigger)
                    if isInSecondAlarm {
                        secondAlert = alertTime
                    } else {
                        alert = alertTime
                    }
                }
                inAlarm = false
                alarmTrigger = nil
                isInSecondAlarm = false
            } else if inAlarm {
                if line.hasPrefix("TRIGGER:") {
                    alarmTrigger = String(line.dropFirst(8))
                } else if line.hasPrefix("DESCRIPTION:") {
                    let description = String(line.dropFirst(12))
                    isInSecondAlarm = description == "2. Hinweis"
                }
            } else if line.hasPrefix("SUMMARY:") {
                title = String(line.dropFirst(8))
            } else if line.hasPrefix("DTSTART") {
                let dateString: String
                if line.contains(";VALUE=DATE:") {
                    isAllDay = true
                    dateString = String(line.split(separator: ":")[1])
                } else {
                    dateString = String(line.dropFirst(8))
                }
                startDate = parseDate(dateString, isAllDay: isAllDay)
            } else if line.hasPrefix("DTEND") {
                let dateString: String
                if line.contains(";VALUE=DATE:") {
                    dateString = String(line.split(separator: ":")[1])
                } else {
                    dateString = String(line.dropFirst(6))
                }
                endDate = parseDate(dateString, isAllDay: isAllDay)
            } else if line.hasPrefix("LOCATION:") {
                location = String(line.dropFirst(9))
            } else if line.hasPrefix("DESCRIPTION:") {
                notes = String(line.dropFirst(12))
            } else if line.hasPrefix("URL:") {
                url = String(line.dropFirst(4))
            } else if line.hasPrefix("RRULE:") {
                recurrence = RecurrenceRule.from(icsString: String(line.dropFirst(6)))
                if recurrence == .custom {
                    customRecurrence = CustomRecurrence.from(icsString: String(line.dropFirst(6)))
                }
            }
        }
        
        return ICSEvent(
            title: title,
            startDate: startDate ?? Date(),
            endDate: endDate ?? Date(),
            isAllDay: isAllDay,
            location: location,
            notes: notes,
            url: url,
            alert: alert,
            secondAlert: secondAlert,
            travelTime: 0,
            recurrence: recurrence,
            customRecurrence: customRecurrence,
            attachments: []
        )
    }
    
    private static func isValidICSDate(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return dateFormatter.date(from: dateString) != nil
    }
    
    private static func parseDate(_ dateString: String, isAllDay: Bool) -> Date? {
        let dateFormatter = DateFormatter()
        if isAllDay {
            dateFormatter.dateFormat = "yyyyMMdd"
        } else {
            dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        }
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
            alert: self.alert,
            secondAlert: self.secondAlert,
            travelTime: self.travelTime,
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
        case none = "NONE"
        case atTime = "AT_TIME"
        case fiveMinutes = "5_MINUTES"
        case tenMinutes = "10_MINUTES"
        case fifteenMinutes = "15_MINUTES"
        case thirtyMinutes = "30_MINUTES"
        case oneHour = "1_HOUR"
        case twoHours = "2_HOURS"
        case oneDay = "1_DAY"
        case twoDays = "2_DAYS"
        case oneWeek = "1_WEEK"
        
        var localizedString: String {
            switch self {
            case .none: return String(localized: "Keine")
            case .atTime: return String(localized: "Zur Startzeit")
            case .fiveMinutes: return String(localized: "5 Minuten vorher")
            case .tenMinutes: return String(localized: "10 Minuten vorher")
            case .fifteenMinutes: return String(localized: "15 Minuten vorher")
            case .thirtyMinutes: return String(localized: "30 Minuten vorher")
            case .oneHour: return String(localized: "1 Stunde vorher")
            case .twoHours: return String(localized: "2 Stunden vorher")
            case .oneDay: return String(localized: "1 Tag vorher")
            case .twoDays: return String(localized: "2 Tage vorher")
            case .oneWeek: return String(localized: "1 Woche vorher")
            }
        }
        
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
        
        static func from(triggerString: String) -> AlertTime {
            switch triggerString {
            case "-PT0M": return .atTime
            case "-PT5M": return .fiveMinutes
            case "-PT10M": return .tenMinutes
            case "-PT15M": return .fifteenMinutes
            case "-PT30M": return .thirtyMinutes
            case "-PT1H": return .oneHour
            case "-PT2H": return .twoHours
            case "-P1D": return .oneDay
            case "-P2D": return .twoDays
            case "-P1W": return .oneWeek
            default: return .none
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
            case .none: return String(localized: "Nie")
            case .daily: return String(localized: "Täglich")
            case .weekly: return String(localized: "Wöchentlich")
            case .monthly: return String(localized: "Monatlich")
            case .yearly: return String(localized: "Jährlich")
            case .custom: return String(localized: "Benutzerdefiniert")
            }
        }
        
        func intervalText(count: Int) -> String {
            switch self {
            case .daily: return count == 1 ? String(localized: "Tag") : String(localized: "Tage")
            case .weekly: return count == 1 ? String(localized: "Woche") : String(localized: "Wochen")
            case .monthly: return count == 1 ? String(localized: "Monat") : String(localized: "Monate")
            case .yearly: return count == 1 ? String(localized: "Jahr") : String(localized: "Jahre")
            default: return ""
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
    
    struct Attachment: Identifiable, Codable, Equatable {
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
        
        static func == (lhs: Attachment, rhs: Attachment) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.fileName == rhs.fileName &&
                   lhs.data == rhs.data &&
                   lhs.type == rhs.type
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
    
    struct CustomRecurrence: Codable, Equatable {
        var frequency: RecurrenceRule
        var interval: Int
        var count: Int?
        var until: Date?
        var weekDays: Set<WeekDay>
        
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
            
            if !weekDays.isEmpty {
                let days = weekDays.map { $0.rawValue }.sorted().joined(separator: ",")
                components.append("BYDAY=\(days)")
            }
            
            return components.joined(separator: ";")
        }
        
        static func from(icsString: String) -> CustomRecurrence? {
            let components = icsString.components(separatedBy: ";")
            
            var frequency: RecurrenceRule = .none
            var interval: Int = 1
            var count: Int?
            var until: Date?
            var weekDays: Set<WeekDay> = []
            
            for component in components {
                if component.hasPrefix("FREQ=") {
                    frequency = RecurrenceRule(rawValue: String(component.dropFirst(5))) ?? .none
                } else if component.hasPrefix("INTERVAL=") {
                    interval = Int(String(component.dropFirst(9))) ?? 1
                } else if component.hasPrefix("COUNT=") {
                    count = Int(String(component.dropFirst(6)))
                } else if component.hasPrefix("UNTIL=") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    until = formatter.date(from: String(component.dropFirst(6)))
                } else if component.hasPrefix("BYDAY=") {
                    let days = String(component.dropFirst(6)).components(separatedBy: ",")
                    weekDays = Set(days.compactMap { WeekDay(rawValue: $0) })
                }
            }
            
            return CustomRecurrence(frequency: frequency, interval: interval, count: count, until: until, weekDays: weekDays)
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

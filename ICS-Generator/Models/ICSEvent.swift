import Foundation

struct ICSEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var location: String?
    var notes: String?
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
    
    func toICSString() -> String {
        var components = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//ICS Generator//DE",
            "BEGIN:VEVENT",
            "UID:\(id.uuidString)",
            "SUMMARY:\(title)",
            isAllDay ? "DTSTART;VALUE=DATE:\(formatDateForICS(startDate, isAllDay: true))" : "DTSTART:\(formatDateForICS(startDate))",
            isAllDay ? "DTEND;VALUE=DATE:\(formatDateForICS(endDate, isAllDay: true))" : "DTEND:\(formatDateForICS(endDate))"
        ]
        
        if let location = location, !location.isEmpty {
            components.append("LOCATION:\(location)")
        }
        
        if let notes = notes, !notes.isEmpty {
            components.append("DESCRIPTION:\(notes)")
        }
        
        if alert != .none {
            components.append("BEGIN:VALARM")
            components.append("ACTION:DISPLAY")
            components.append("DESCRIPTION:Reminder")
            components.append("TRIGGER:\(alert.triggerValue)")
            components.append("END:VALARM")
        }
        
        if recurrence != .none {
            if recurrence == .custom, let custom = customRecurrence {
                components.append("RRULE:\(custom.toRRuleString())")
            } else {
                components.append("RRULE:FREQ=\(recurrence.rawValue)")
            }
        }
        
        if !attachments.isEmpty {
            for attachment in attachments {
                components.append("ATTACH;FILENAME=\(attachment.fileName);ENCODING=BASE64:\(attachment.data.base64EncodedString())")
            }
        }
        
        components.append("END:VEVENT")
        components.append("END:VCALENDAR")
        
        return components.joined(separator: "\r\n")
    }
    
    private func formatDateForICS(_ date: Date, isAllDay: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        
        if isAllDay {
            formatter.dateFormat = "yyyyMMdd"
        } else {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        }
        
        return formatter.string(from: date)
    }
}

extension ICSEvent {
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
    }
    
    enum RecurrenceRule: String, Codable {
        case none = "NONE"
        case daily = "DAILY"
        case weekly = "WEEKLY"
        case monthly = "MONTHLY"
        case yearly = "YEARLY"
        case custom = "CUSTOM"
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

import Foundation

enum EventFilter: Int, CaseIterable, Identifiable {
    case all
    case upcoming
    case past
    case today
    case thisWeek
    case thisMonth
    
    var id: Int { rawValue }
    
    var description: String {
        switch self {
        case .all:
            return "Alle"
        case .upcoming:
            return "Zukünftige"
        case .past:
            return "Vergangene"
        case .today:
            return "Heute"
        case .thisWeek:
            return "Diese Woche"
        case .thisMonth:
            return "Dieser Monat"
        }
    }
    
    func filter(_ events: [ICSEvent]) -> [ICSEvent] {
        let now = Date()
        let calendar = Calendar.current
        
        switch self {
        case .all:
            return events
            
        case .upcoming:
            return events.filter { $0.startDate > now }
            
        case .past:
            return events.filter { $0.startDate < now }
            
        case .today:
            return events.filter { calendar.isDate($0.startDate, inSameDayAs: now) }
            
        case .thisWeek:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                return []
            }
            return events.filter { $0.startDate >= weekStart && $0.startDate < weekEnd }
            
        case .thisMonth:
            guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                return []
            }
            return events.filter { $0.startDate >= monthStart && $0.startDate < monthEnd }
        }
    }
}

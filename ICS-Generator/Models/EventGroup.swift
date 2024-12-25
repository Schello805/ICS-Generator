import Foundation

struct EventGroup: Identifiable {
    let month: Date
    let events: [ICSEvent]
    
    var id: Date { month }
}

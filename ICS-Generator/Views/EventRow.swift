import SwiftUI

struct EventRow: View {
    let event: ICSEvent
    @State private var isPressed = false
    @State private var showCopiedFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Location Row
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Date and Time Row
            HStack(spacing: 4) {
                Image(systemName: event.isAllDay ? "calendar" : "clock")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(formatEventDate(event))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if event.recurrence != .none {
                    Image(systemName: "repeat")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if showCopiedFeedback {
                    Text("Kopiert!")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }
            
            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }
    
    private func formatEventDate(_ event: ICSEvent) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        
        if event.isAllDay {
            formatter.dateStyle = .medium
            if Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate) {
                return formatter.string(from: event.startDate)
            } else {
                return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
            }
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            if Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate) {
                return "\(formatter.string(from: event.startDate)) - \(DateFormatter.timeOnly.string(from: event.endDate))"
            } else {
                return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
            }
        }
    }
}

struct EventRow_Previews: PreviewProvider {
    static var previews: some View {
        EventRow(event: ICSEvent(
            title: "Beispieltermin",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            isAllDay: false,
            location: "Musterstraße 1",
            notes: "Dies ist ein Beispieltermin mit Notizen.",
            alert: .fifteenMinutes,
            recurrence: .daily
        ))
        .padding()
    }
}

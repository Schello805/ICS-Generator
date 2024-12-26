import SwiftUI

struct EventListItem: View {
    let event: ICSEvent
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        return formatter
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = dateFormatter
        formatter.dateFormat = "dd"
        return formatter
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = dateFormatter
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = dateFormatter
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Date Column
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: event.startDate))
                    .font(.title2)
                    .bold()
                Text(monthFormatter.string(from: event.startDate))
                    .font(.caption)
                    .textCase(.uppercase)
            }
            .frame(width: 50)
            .foregroundStyle(.secondary)
            
            // Content Column
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    // Time
                    Label(event.isAllDay ? "Ganztägig" : "\(timeFormatter.string(from: event.startDate)) - \(timeFormatter.string(from: event.endDate))",
                          systemImage: "clock")
                    
                    // Location if available
                    if let location = event.location {
                        Label(location, systemImage: "location")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            
            Spacer()
            
            // Action Menu
            Menu {
                Button(action: onEdit) {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: onDelete) {
                    Label("Löschen", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .contextMenu {
            Button(action: onEdit) {
                Label("Bearbeiten", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}

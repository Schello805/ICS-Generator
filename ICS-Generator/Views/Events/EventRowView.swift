import SwiftUI

struct EventRowView: View {
    let event: ICSEvent
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: EventViewModel
    @State private var showingDeleteAlert = false
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(event.startDate)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }
    
    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE"
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Date Column
            VStack(alignment: .center, spacing: 4) {
                Text(dateFormatter.string(from: event.startDate))
                    .font(.caption)
                    .foregroundColor(isToday ? .white : .primary)
                Text(weekdayFormatter.string(from: event.startDate))
                    .font(.caption2)
                    .foregroundColor(isToday ? .white : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isToday ? Color.accentColor : Color.clear)
                    )
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
            
            // Content Column
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if let location = event.location, !location.isEmpty {
                    Label(title: { Text(location) }, icon: { Image(systemName: "mappin") })
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    if event.isAllDay {
                        Text("Ganztägig")
                    } else {
                        let startTime = event.startDate.formatted(.dateTime.hour().minute())
                        let endTime = event.endDate.formatted(.dateTime.hour().minute())
                        Text("\(startTime) - \(endTime)")
                    }
                    
                    if event.alert != .none {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Menü statt Chevron
            Menu {
                Button(action: {
                    viewModel.editingEvent = event
                    viewModel.showingEditSheet = true
                }) {
                    Label(title: { Text("Bearbeiten") }, icon: { Image(systemName: "pencil") })
                }
                
                Button(role: .destructive, action: {
                    viewModel.deleteEvent(event)
                }) {
                    Label(title: { Text("Löschen") }, icon: { Image(systemName: "trash") })
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        EventRowView(event: ICSEvent(
            title: "Wichtiges Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            location: "Konferenzraum 1",
            alert: .atTime
        ), viewModel: EventViewModel())
        
        EventRowView(event: ICSEvent(
            title: "Geburtstag",
            startDate: Date().addingTimeInterval(86400),
            endDate: Date().addingTimeInterval(86400),
            isAllDay: true
        ), viewModel: EventViewModel())
        
        EventRowView(event: ICSEvent(
            title: "Lange Konferenz mit sehr langem Titel der abgeschnitten werden sollte",
            startDate: Date().addingTimeInterval(7*86400),
            endDate: Date().addingTimeInterval(8*86400),
            location: "Ein sehr langer Ort der ebenfalls abgeschnitten werden sollte",
            alert: .none
        ), viewModel: EventViewModel())
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

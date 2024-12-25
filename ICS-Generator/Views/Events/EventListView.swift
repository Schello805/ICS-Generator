import SwiftUI

struct EventListView: View {
    let events: [ICSEvent]
    @Binding var selectedEvent: ICSEvent?
    @Binding var isRefreshing: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupEventsByMonth(events), id: \.month) { group in
                    MonthSection(group: group, selectedEvent: $selectedEvent)
                }
            }
            .padding()
        }
        .refreshable {
            isRefreshing = true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isRefreshing = false
        }
    }
    
    private func groupEventsByMonth(_ events: [ICSEvent]) -> [EventGroup] {
        let grouped = Dictionary(grouping: events) { event in
            Calendar.current.startOfMonth(for: event.startDate)
        }
        return grouped.map { EventGroup(month: $0.key, events: $0.value.sorted { $0.startDate < $1.startDate }) }
            .sorted { $0.month < $1.month }
    }
}

struct MonthSection: View {
    let group: EventGroup
    @Binding var selectedEvent: ICSEvent?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(group.month.formatted(.dateTime.month(.wide).year()))
                .font(.title2)
                .bold()
                .foregroundColor(CustomColors.text)
            
            ForEach(group.events) { event in
                EventRowView(event: event)
                    .onTapGesture {
                        selectedEvent = event
                    }
            }
        }
    }
}

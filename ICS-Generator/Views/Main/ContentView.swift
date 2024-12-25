import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = EventViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                EventsView()
                    .environmentObject(viewModel)
            }
            .tabItem {
                Label("Termine", systemImage: "calendar")
            }
            .tag(0)
            
            NavigationStack {
                SettingsView()
                    .environmentObject(viewModel)
            }
            .tabItem {
                Label("Einstellungen", systemImage: "gear")
            }
            .tag(1)
        }
        .environmentObject(viewModel)
    }
}

struct EventsView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @State private var showAddEvent = false
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedFilter: EventFilter = .all
    @State private var selectedEvent: ICSEvent?
    @State private var isRefreshing = false
    @State private var showingExportOptions = false
    @State private var showingDeleteConfirmation = false
    @State private var showingImportSheet = false
    @State private var showingPreview = false
    @State private var previewContent: String = ""
    
    private let animation = Animation.spring(response: 0.5, dampingFraction: 0.8)
    
    var body: some View {
        ZStack {
            CustomColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                SearchAndFilterView(
                    searchText: $searchText,
                    selectedFilter: $selectedFilter,
                    animation: animation
                )
                .padding(.horizontal)
                .padding(.top)
                
                if viewModel.events.isEmpty {
                    ScrollView {
                        EmptyStateView(showAddEvent: $showAddEvent)
                            .transition(.opacity)
                    }
                } else {
                    EventListView(
                        events: viewModel.events,
                        selectedEvent: $selectedEvent,
                        isRefreshing: $isRefreshing
                    )
                }
                
                Spacer(minLength: 16) // Reduzierter Platz für den FAB
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                FloatingActionButton(action: { showAddEvent = true })
                    .padding(.bottom, 8)
            }
        }
        .navigationTitle("Termine")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EventsMenuButton(
                    showingFilters: $showingFilters,
                    showAddEvent: $showAddEvent,
                    showingImportSheet: $showingImportSheet,
                    showingExportOptions: $showingExportOptions,
                    showingDeleteConfirmation: $showingDeleteConfirmation,
                    hasEvents: !viewModel.events.isEmpty
                )
            }
        }
        .sheet(isPresented: $showAddEvent) {
            NavigationStack {
                EventEditorView(event: nil)
            }
        }
        .sheet(item: $selectedEvent) { event in
            NavigationStack {
                EventEditorView(event: event)
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            NavigationStack {
                ICSImportView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingPreview) {
            ICSPreviewView(icsContent: previewContent)
        }
        .confirmationDialog(
            "ICS-Datei exportieren",
            isPresented: $showingExportOptions,
            titleVisibility: .visible
        ) {
            Button("Vorschau anzeigen") {
                previewContent = viewModel.exportToString()
                showingPreview = true
            }
            
            Button("Direkt teilen") {
                viewModel.exportDirectly()
            }
            
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Wählen Sie eine Option")
        }
        .confirmationDialog(
            "Alle Termine löschen?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Alle Termine löschen", role: .destructive) {
                viewModel.deleteAllEvents()
            }
            
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden")
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

struct SearchAndFilterView: View {
    @Binding var searchText: String
    @Binding var selectedFilter: EventFilter
    let animation: Animation
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(CustomColors.secondaryText)
                TextField("Termine durchsuchen", text: $searchText)
            }
            .padding(10)
            .background(CustomColors.secondaryBackground)
            .cornerRadius(10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.title,
                            icon: filter.icon,
                            isSelected: filter == selectedFilter
                        ) {
                            withAnimation(animation) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

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

struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(CustomColors.accent)
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 2)
                }
                .padding()
                .transition(.scale)
            }
        }
    }
}

struct EventsMenuButton: View {
    @Binding var showingFilters: Bool
    @Binding var showAddEvent: Bool
    @Binding var showingImportSheet: Bool
    @Binding var showingExportOptions: Bool
    @Binding var showingDeleteConfirmation: Bool
    let hasEvents: Bool
    
    var body: some View {
        Menu {
            Button(action: { showingFilters.toggle() }) {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
            
            Button(action: { showAddEvent = true }) {
                Label("Termin erstellen", systemImage: "plus.circle")
            }
            
            Button(action: { showingImportSheet = true }) {
                Label("ICS importieren", systemImage: "square.and.arrow.down")
            }
            
            Button(action: { showingExportOptions = true }) {
                Label("Alle exportieren", systemImage: "square.and.arrow.up")
            }
            .disabled(!hasEvents)
            
            if hasEvents {
                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    Label("Alle löschen", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(CustomColors.accent)
        }
    }
}

struct MonthSection: View {
    let group: EventGroup
    @Binding var selectedEvent: ICSEvent?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM."
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(group.month.formatted(.dateTime.month(.wide).year()))
                .font(.title2)
                .bold()
                .foregroundColor(CustomColors.text)
            
            ForEach(group.events) { event in
                Button(action: { selectedEvent = event }) {
                    HStack(spacing: 16) {
                        // Datum und Zeit
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dateFormatter.string(from: event.startDate))
                                .font(.subheadline)
                                .bold()
                            Text(timeFormatter.string(from: event.startDate))
                                .font(.caption)
                        }
                        .foregroundColor(CustomColors.accent)
                        .frame(width: 60, alignment: .leading)
                        
                        // Event Details
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.headline)
                                .foregroundColor(CustomColors.text)
                            
                            if let location = event.location, !location.isEmpty {
                                HStack {
                                    Image(systemName: "location")
                                        .font(.caption)
                                    Text(location)
                                        .font(.subheadline)
                                }
                                .foregroundColor(CustomColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CustomColors.secondaryText)
                    }
                    .padding()
                    .background(CustomColors.secondaryBackground)
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct EventCard: View {
    let event: ICSEvent
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Zeitanzeige
            VStack(spacing: 4) {
                if event.isAllDay {
                    Text("Ganztägig")
                        .font(.headline)
                        .foregroundColor(CustomColors.accent)
                } else {
                    Text(event.startDate.formatted(.dateTime.hour().minute()))
                        .font(.headline)
                        .foregroundColor(CustomColors.accent)
                    
                    if Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate) {
                        Text(event.endDate.formatted(.dateTime.hour().minute()))
                            .font(.subheadline)
                            .foregroundColor(CustomColors.secondaryText)
                    }
                }
            }
            .frame(width: 60)
            
            // Vertikale Linie
            Rectangle()
                .fill(CustomColors.accent.opacity(0.3))
                .frame(width: 2)
                .padding(.vertical, 4)
            
            // Event Details
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(CustomColors.text)
                
                if let location = event.location, !location.isEmpty {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(CustomColors.accent.opacity(0.8))
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(CustomColors.secondaryText)
                    }
                }
                
                if let urlString = event.url, let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(CustomColors.accent.opacity(0.8))
                            Text(url.host ?? "Website")
                                .font(.subheadline)
                                .foregroundColor(CustomColors.accent)
                        }
                    }
                }
                
                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(CustomColors.secondaryText)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Erinnerungs-Indikator
            if event.alert != .none {
                Circle()
                    .fill(getAlertColor(event.alert))
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(CustomColors.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                radius: 8, x: 0, y: 4)
    }
    
    private func getAlertColor(_ alert: ICSEvent.AlertTime) -> Color {
        switch alert {
        case .none: return .gray
        case .atTime: return .blue
        case .fiveMinutes: return .orange
        case .tenMinutes: return .red
        case .fifteenMinutes: return .purple
        case .thirtyMinutes: return .green
        case .oneHour: return .yellow
        case .twoHours: return .mint
        case .oneDay: return .indigo
        case .twoDays: return .brown
        case .oneWeek: return .cyan
        }
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? CustomColors.accent : CustomColors.secondaryBackground)
            .foregroundColor(isSelected ? .white : CustomColors.text)
            .cornerRadius(20)
            .animation(.spring(), value: isSelected)
        }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

struct EventGroup {
    let month: Date
    let events: [ICSEvent]
}

enum EventFilter: CaseIterable {
    case all
    case today
    case upcoming
    case past
    
    var title: String {
        switch self {
        case .all: return "Alle"
        case .today: return "Heute"
        case .upcoming: return "Kommend"
        case .past: return "Vergangen"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "calendar"
        case .today: return "star"
        case .upcoming: return "arrow.right"
        case .past: return "clock"
        }
    }
    
    func filter(_ events: [ICSEvent]) -> [ICSEvent] {
        let now = Date()
        switch self {
        case .all:
            return events
        case .today:
            return events.filter { Calendar.current.isDateInToday($0.startDate) }
        case .upcoming:
            return events.filter { $0.startDate > now }
        case .past:
            return events.filter { $0.startDate < now }
        }
    }
}

struct EventRowView: View {
    let event: ICSEvent
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                
                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "mappin")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if event.isAllDay {
                        Text(String(localized: "Ganztägig"))
                    } else {
                        let startTime = event.startDate.formatted(.dateTime.hour().minute())
                        let endTime = event.endDate.formatted(.dateTime.hour().minute())
                        Text("\(startTime) - \(endTime)")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if event.alert != .none {
                Image(systemName: "bell.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}

import SwiftUI
import os.log

struct EventsView: View {
    @EnvironmentObject var viewModel: EventViewModel
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ICS-Generator", category: "EventsView")
    @State private var showingAddEvent = false
    @State private var eventToEdit: ICSEvent?
    @State private var showingImportSheet = false
    @State private var showingValidationSheet = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var selectedFilter: EventFilter = .all
    
    private var filteredEvents: [ICSEvent] {
        // Zuerst nach Filter filtern
        let filtered = selectedFilter.filter(viewModel.events)
        
        // Wenn kein Suchtext, gib gefilterte Events zurück
        guard !searchText.isEmpty else {
            return filtered
        }
        
        // Suche in gefilterten Events
        return filtered.filter { event in
            let searchableFields = [
                event.title,
                event.location ?? "",
                event.notes ?? ""
            ]
            
            return searchableFields.contains { field in
                field.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var groupedEvents: [(String, [ICSEvent])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        dateFormatter.locale = Locale(identifier: "de_DE")
        
        let grouped = Dictionary(grouping: filteredEvents) { event in
            dateFormatter.string(from: event.startDate)
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var toolbarContent: some View {
        if !viewModel.events.isEmpty {
            HStack(spacing: 16) {
                Menu {
                    Button(action: { showingImportSheet = true }) {
                        Label("ICS importieren", systemImage: "square.and.arrow.down")
                    }
                    Button(action: { showingValidationSheet = true }) {
                        Label("ICS validieren", systemImage: "checkmark.shield")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                Button(action: { showingAddEvent = true }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.events.isEmpty {
            EmptyStateView(
                showAddEvent: $showingAddEvent,
                showingImportSheet: $showingImportSheet,
                showingValidationSheet: $showingValidationSheet
            )
        } else {
            eventsList
        }
    }
    
    @ViewBuilder
    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(groupedEvents, id: \.0) { month, events in
                    Section(header: MonthHeaderView(title: month)) {
                        VStack(spacing: 12) {
                            ForEach(events) { event in
                                EventListItem(
                                    event: event,
                                    onEdit: { eventToEdit = event },
                                    onDelete: { viewModel.deleteEvent(event) }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    SearchAndFilterView(
                        searchText: $searchText,
                        selectedFilter: $selectedFilter,
                        showingFilterSheet: $showingFilterSheet
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    
                    mainContent
                }
            }
            .navigationTitle("Termine")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.previewContent = viewModel.exportToString(events: filteredEvents)
                        viewModel.showingExportOptions = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEvent = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingValidationSheet) {
                NavigationStack {
                    SettingsView(selectedTab: .icsValidation)
                        .environmentObject(viewModel)
                }
            }
            .sheet(item: $eventToEdit) { event in
                EventEditorView(event: event)
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingImportSheet) {
                NavigationStack {
                    SettingsView(selectedTab: .icsImport)
                        .environmentObject(viewModel)
                }
            }
            .sheet(isPresented: $viewModel.showingExportOptions) {
                ICSPreviewView(icsContent: viewModel.previewContent, events: filteredEvents)
            }
            .alert("Termin löschen", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) {
                    viewModel.cancelDelete()
                }
                Button("Löschen", role: .destructive) {
                    viewModel.confirmDelete()
                }
            } message: {
                if let event = viewModel.eventToDelete {
                    Text("Möchten Sie den Termin '\(event.title)' wirklich löschen?")
                }
            }
            .alert("Fehler", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteEvent(_ event: ICSEvent) {
        viewModel.deleteEvent(event)
    }
}

struct EventsView_Previews: PreviewProvider {
    static var previews: some View {
        EventsView()
    }
}

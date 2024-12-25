import SwiftUI

struct EventsView: View {
    @EnvironmentObject var viewModel: EventViewModel
    @State private var selectedEvent: ICSEvent?
    @State private var showAddEvent = false
    @State private var showEditEvent = false
    @State private var isRefreshing = false
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var selectedFilter: EventFilter = .all
    @State private var showingImportSheet = false
    @State private var showingExportOptions = false
    @State private var showingDeleteConfirmation = false
    @State private var showingPreview = false
    @State private var showingValidator = false
    @State private var previewContent: String = ""
    
    private var filteredEvents: [ICSEvent] {
        let filtered = selectedFilter.filter(viewModel.events)
        if searchText.isEmpty {
            return filtered
        }
        return filtered.filter { event in
            event.title.localizedCaseInsensitiveContains(searchText) ||
            (event.location ?? "").localizedCaseInsensitiveContains(searchText) ||
            (event.notes ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Search and Filter Bar
                SearchAndFilterView(
                    searchText: $searchText,
                    selectedFilter: $selectedFilter,
                    showingFilterSheet: $showingFilterSheet
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    Color(.systemBackground)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )
                
                // Content
                ScrollView {
                    // Add some top padding to avoid shadow overlap
                    Color.clear.frame(height: 8)
                    
                    if filteredEvents.isEmpty {
                        EmptyStateView(
                            title: "Keine Termine",
                            message: "Erstellen Sie einen neuen Termin mit dem + Button",
                            systemImage: "calendar"
                        )
                        .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredEvents) { event in
                                EventRowView(event: event, viewModel: viewModel)
                                    .onTapGesture {
                                        selectedEvent = event
                                        showEditEvent = true
                                    }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom)
                    }
                }
                .refreshable {
                    isRefreshing = true
                    viewModel.loadEvents()
                    isRefreshing = false
                }
            }
            
            // Add Event Button
            AddEventButton {
                showAddEvent = true
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventView(viewModel: viewModel)
        }
        .sheet(isPresented: $showEditEvent) {
            if let event = selectedEvent {
                NavigationStack {
                    EventEditorView(event: event)
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView(selectedFilter: $selectedFilter)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView()
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(content: previewContent)
        }
        .sheet(isPresented: $showingValidator) {
            ICSValidatorView()
        }
        .alert("Alle Termine löschen?", isPresented: $showingDeleteConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                viewModel.deleteAllEvents()
            }
        } message: {
            Text("Möchten Sie wirklich alle Termine löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }
}

struct EventsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EventsView()
                .environmentObject(EventViewModel())
        }
    }
}

import SwiftUI

struct EventsView: View {
    @EnvironmentObject var viewModel: EventViewModel
    @State private var selectedEvent: ICSEvent?
    @State private var showAddEvent = false
    @State private var isRefreshing = false
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var selectedFilter: EventFilter = .all
    
    var body: some View {
        VStack {
            // Search and Filter Bar
            SearchAndFilterView(
                searchText: $searchText,
                selectedFilter: $selectedFilter,
                showingFilterSheet: $showingFilterSheet
            )
            .padding(.horizontal)
            
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
            
            Spacer(minLength: 16)
        }
        
        // Floating Action Button
        VStack {
            Spacer()
            FloatingActionButton(action: { showAddEvent = true })
                .padding(.bottom, 8)
        }
        .navigationTitle("Termine")
        .sheet(isPresented: $showAddEvent) {
            AddEventView(viewModel: viewModel)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, viewModel: viewModel)
        }
    }
}

#Preview {
    NavigationStack {
        EventsView()
            .environmentObject(EventViewModel())
    }
}

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: EventViewModel
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                EventsView()
            }
            .tabItem {
                Label("Termine", systemImage: "calendar")
            }
            .tag(0)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Einstellungen", systemImage: "gear")
            }
            .tag(1)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.loadEvents()
            }
        }
        .onAppear {
            viewModel.loadEvents()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mockViewModel = EventViewModel()
        // Add some test events
        mockViewModel.events = [
            ICSEvent(
                title: "Test Event 1",
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600),
                isAllDay: false,
                location: nil,
                notes: nil,
                url: nil,
                alert: .fifteenMinutes,
                secondAlert: .none,
                travelTime: 0,
                recurrence: .none,
                customRecurrence: nil,
                attachments: []
            ),
            ICSEvent(
                title: "Test Event 2",
                startDate: Date().addingTimeInterval(7200),
                endDate: Date().addingTimeInterval(10800),
                isAllDay: false,
                location: nil,
                notes: nil,
                url: nil,
                alert: .fifteenMinutes,
                secondAlert: .none,
                travelTime: 0,
                recurrence: .none,
                customRecurrence: nil,
                attachments: []
            )
        ]
        
        return ContentView()
            .environmentObject(mockViewModel)
    }
}

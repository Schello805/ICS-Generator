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
        ContentView()
            .environmentObject(EventViewModel())
    }
}

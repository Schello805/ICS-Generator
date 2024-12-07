import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    
    var body: some View {
        TabView {
            EventsView()
                .tabItem {
                    Label(NSLocalizedString("Termine", comment: "Events tab"), systemImage: "calendar")
                }
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                SettingsView()
                    .tabItem {
                        Label(NSLocalizedString("Einstellungen", comment: "Settings tab"), systemImage: "gear")
                    }
            } else {
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label(NSLocalizedString("Einstellungen", comment: "Settings tab"), systemImage: "gear")
                }
            }
        }
        .environmentObject(viewModel)
        .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 800 : nil)
        .frame(maxWidth: .infinity)
    }
}

struct EventsView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if viewModel.events.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.accentColor)
                            
                            Text(NSLocalizedString("Keine Termine", comment: "Shown when no events exist"))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(NSLocalizedString("Erstellen Sie Ihren ersten Termin und exportieren Sie ihn als ICS-Datei.", comment: "Empty state description"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                FeatureRow(
                                    icon: "calendar.badge.plus",
                                    title: NSLocalizedString("Termine erstellen", comment: "Feature row title"),
                                    description: NSLocalizedString("Erstellen Sie Termine mit allen wichtigen Details.", comment: "Feature row description")
                                )
                                
                                Divider()
                                
                                FeatureRow(
                                    icon: "square.and.arrow.up",
                                    title: NSLocalizedString("Als ICS exportieren", comment: "Feature row title"),
                                    description: NSLocalizedString("Exportieren Sie Ihre Termine im ICS-Format.", comment: "Feature row description")
                                )
                                
                                Divider()
                                
                                FeatureRow(
                                    icon: "bell",
                                    title: NSLocalizedString("Erinnerungen", comment: "Feature row title"),
                                    description: NSLocalizedString("Verpassen Sie keine wichtigen Termine.", comment: "Feature row description")
                                )
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            
                            Button {
                                viewModel.showingNewEventSheet = true
                            } label: {
                                Label(NSLocalizedString("Termin erstellen", comment: "Create event button"), systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ForEach(viewModel.events) { event in
                            EventRowView(event: event)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            viewModel.deleteEvent(event)
                                        }
                                    } label: {
                                        Label(NSLocalizedString("Löschen", comment: "Delete button"), systemImage: "trash")
                                    }
                                    
                                    Button {
                                        viewModel.editEvent(event)
                                    } label: {
                                        Label(NSLocalizedString("Bearbeiten", comment: "Edit button"), systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("Termine", comment: "Events title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingNewEventSheet = true
                    } label: {
                        Label(NSLocalizedString("Termin hinzufügen", comment: "Add event button"), systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingNewEventSheet) {
                NavigationStack {
                    EventEditorView(event: nil)
                }
            }
            .sheet(item: $viewModel.editingEvent) { event in
                NavigationStack {
                    EventEditorView(event: event)
                }
            }
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
                        Text(NSLocalizedString("Ganztägig", comment: "All day event"))
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(EventViewModel())
}

//
//  ContentView.swift
//  ICS-Generator
//
//  Created by Michael Schellenberger on 01.12.24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = EventViewModel()
    
    var body: some View {
        TabView {
            EventsView()
                .tabItem {
                    Label("Termine", systemImage: "calendar")
                }
            
            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gear")
                }
        }
        .environmentObject(viewModel)
    }
}

struct EventsView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.events.isEmpty {
                    EmptyStateView()
                } else {
                    EventList()
                }
            }
            .navigationTitle("ICS Generator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingNewEventSheet = true
                    } label: {
                        Image(systemName: "plus")
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

struct EventList: View {
    @EnvironmentObject private var viewModel: EventViewModel
    
    var groupedEvents: [(String, [ICSEvent])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.events) { event in
            let date = event.startDate
            if calendar.isDateInToday(date) {
                return "Heute"
            } else if calendar.isDateInTomorrow(date) {
                return "Morgen"
            } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
                let weekday = calendar.component(.weekday, from: date)
                return calendar.weekdaySymbols[weekday - 1]
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: date)
            }
        }
        return grouped.sorted { date1, date2 in
            let event1 = date1.value.min { $0.startDate < $1.startDate }
            let event2 = date2.value.min { $0.startDate < $1.startDate }
            return event1?.startDate ?? Date() < event2?.startDate ?? Date()
        }
    }
    
    var body: some View {
        List {
            ForEach(groupedEvents, id: \.0) { section, events in
                Section(header: 
                    Text(section)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .textCase(nil)
                        .padding(.vertical, 8)
                ) {
                    ForEach(events.sorted { $0.startDate < $1.startDate }, id: \.self) { event in
                        EventRowView(event: event)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.showingNewEventSheet = true
                    } label: {
                        Label("Neuer Termin", systemImage: "calendar.badge.plus")
                    }
                    
                    Button {
                        viewModel.showingImportSheet = true
                    } label: {
                        Label("ICS importieren", systemImage: "square.and.arrow.down")
                    }
                    
                    if !viewModel.events.isEmpty {
                        Button {
                            viewModel.showingExportOptions = true
                        } label: {
                            Label("Alle exportieren", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.showingDeleteConfirmation = true
                        } label: {
                            Label("Alle löschen", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            await viewModel.refreshEvents()
        }
        .alert("Alle Termine löschen?", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                viewModel.deleteAllEvents()
            }
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }
}

struct EventRowView: View {
    let event: ICSEvent
    @EnvironmentObject private var viewModel: EventViewModel
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    
    private func createAndShareICSFile(for event: ICSEvent) -> URL {
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent("\(event.title).ics")
        
        do {
            try event.toICSString().write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error creating ICS file: \(error)")
            return fileURL
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                Text(formatEventTime(event))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            if let location = event.location {
                HStack {
                    Image(systemName: "mappin")
                        .foregroundColor(.gray)
                    Text(location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .contextMenu {
            Button {
                viewModel.editEvent(event)
            } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }
            
            Button {
                showingShareSheet = true
            } label: {
                Label("Teilen", systemImage: "square.and.arrow.up")
            }
            
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Löschen", systemImage: "trash")
            }
            
            Button {
                viewModel.editEvent(event)
            } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }
            .tint(.blue)
            
            Button {
                showingShareSheet = true
            } label: {
                Label("Teilen", systemImage: "square.and.arrow.up")
            }
            .tint(.green)
        }
        .sheet(isPresented: $showingShareSheet) {
            let fileURL = createAndShareICSFile(for: event)
            ShareSheet(activityItems: [fileURL])
        }
        .alert("Termin löschen", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                viewModel.deleteEvent(event)
            }
        } message: {
            Text("Möchten Sie diesen Termin wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }
    
    private func formatEventTime(_ event: ICSEvent) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        
        if event.isAllDay {
            formatter.dateStyle = .medium
            if Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate) {
                return formatter.string(from: event.startDate)
            } else {
                return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
            }
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct EmptyStateView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Noch keine Termine")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Erstellen Sie Ihren ersten Termin und exportieren Sie ihn als ICS-Datei.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "calendar.badge.plus",
                    title: "Termine erstellen",
                    description: "Erstellen Sie Termine mit allen wichtigen Details wie Datum, Ort und Erinnerungen."
                )
                
                FeatureRow(
                    icon: "arrow.up.doc",
                    title: "Als ICS exportieren",
                    description: "Exportieren Sie Ihre Termine im ICS-Format für die Verwendung in anderen Kalender-Apps."
                )
                
                FeatureRow(
                    icon: "bell",
                    title: "Erinnerungen",
                    description: "Legen Sie Erinnerungen fest, damit Sie keine wichtigen Termine verpassen."
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding()
            
            Button {
                viewModel.showingNewEventSheet = true
            } label: {
                Label("Termin erstellen", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(EventViewModel())
}

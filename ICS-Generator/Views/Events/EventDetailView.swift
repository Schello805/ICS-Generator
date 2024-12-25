import SwiftUI
import os.log

struct EventDetailView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ICS-Generator", category: "EventDetailView")
    
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var editedEvent: ICSEvent
    
    init(event: ICSEvent, viewModel: EventViewModel) {
        self.viewModel = viewModel
        _editedEvent = State(initialValue: event)
    }
    
    var body: some View {
        Form {
            // Details Section
            Section(header: Text("Details")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(editedEvent.title)
                        .font(.headline)
                    
                    if let location = editedEvent.location {
                        HStack {
                            Image(systemName: "location.fill")
                            Text(location)
                        }
                    }
                    
                    if let url = editedEvent.url {
                        Link(destination: URL(string: url)!) {
                            HStack {
                                Image(systemName: "link")
                                Text(url)
                            }
                        }
                    }
                    
                    if editedEvent.travelTime > 0 {
                        HStack {
                            Image(systemName: "car.fill")
                            Text("\(editedEvent.travelTime) Minuten Reisezeit")
                        }
                    }
                }
            }
            
            // Datum Section
            Section(header: Text("Datum")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(editedEvent.formattedDate)
                }
            }
            
            // Notizen Section
            if let notes = editedEvent.notes {
                Section(header: Text("Notizen")) {
                    Text(notes)
                }
            }
        }
        .navigationTitle("Termin")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                }
            }
            
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                EventEditorView(event: $editedEvent)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") {
                                showingEditSheet = false
                            }
                        }
                    }
            }
        }
        .alert("Termin löschen?", isPresented: $showingDeleteAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Löschen", role: .destructive) {
                logger.info("Deleting event: \(editedEvent.title)")
                viewModel.deleteEvent(editedEvent)
                dismiss()
            }
        } message: {
            Text("Möchten Sie den Termin wirklich löschen?")
        }
        .onChange(of: showingEditSheet) { _, isShowing in
            if !isShowing {
                logger.info("Sheet closed, updating event in view model")
                viewModel.updateEvent(editedEvent)
            }
        }
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EventDetailView(
                event: ICSEvent(
                    title: "Test Event",
                    startDate: Date(),
                    endDate: Date().addingTimeInterval(3600)
                ),
                viewModel: EventViewModel()
            )
        }
    }
}

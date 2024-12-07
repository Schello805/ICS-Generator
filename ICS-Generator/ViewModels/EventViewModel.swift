import SwiftUI
import UniformTypeIdentifiers

class EventViewModel: ObservableObject {
    @Published var events: [ICSEvent] = []
    @Published var showingError = false
    @Published var showingSuccess = false
    @Published var errorMessage: String = ""
    @Published var isExporting = false
    
    // UI State
    @Published var selectedEvent: ICSEvent?
    @Published var editingEvent: ICSEvent?
    @Published var showingNewEventSheet = false
    @Published var showingEditSheet = false
    @Published var showingSettings = false
    @Published var showingExportOptions = false
    @Published var showingImportSheet = false
    @Published var showingValidatorSheet = false
    @Published var showingDeleteConfirmation = false
    
    init() {
        loadEvents()
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: "events") {
            if let decodedEvents = try? JSONDecoder().decode([ICSEvent].self, from: data) {
                events = decodedEvents
            }
        }
    }
    
    private func saveEvents() {
        if let encodedData = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encodedData, forKey: "events")
        }
    }
    
    func addEvent(_ event: ICSEvent) {
        events.append(event)
        saveEvents()
    }
    
    func updateEvent(_ event: ICSEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
        }
    }
    
    func deleteEvent(_ event: ICSEvent) {
        events.removeAll { $0.id == event.id }
        saveEvents()
    }
    
    func deleteAllEvents() {
        events.removeAll()
        saveEvents()
    }
    
    func editEvent(_ event: ICSEvent) {
        editingEvent = event
        showingEditSheet = true
    }
    
    func shareEvent(_ event: ICSEvent) {
        let icsString = generateICSString(for: [event])
        Platform.share(items: [icsString]) { [self] success in
            if success {
                self.showSuccess()
            }
        }
    }
    
    private func showSuccess() {
        showingSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showingSuccess = false
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func importICSString(_ icsString: String) {
        guard let event = ICSEvent.from(icsString: icsString) else {
            showError("Ungültiges ICS-Format")
            return
        }
        addEvent(event)
    }
    
    private func generateICSString(for events: [ICSEvent]) -> String {
        var components = [String]()
        components.append("BEGIN:VCALENDAR")
        components.append("VERSION:2.0")
        components.append("PRODID:-//ICS Generator//DE")
        
        for event in events {
            components.append(event.toICSString())
        }
        
        components.append("END:VCALENDAR")
        return components.joined(separator: "\r\n")
    }
    
    @MainActor
    func validateICSString(_ icsString: String) -> Bool {
        guard let _ = ICSEvent.from(icsString: icsString) else {
            return false
        }
        return true
    }
}

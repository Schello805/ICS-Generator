import SwiftUI
import UniformTypeIdentifiers
import UIKit
import os.log

class EventViewModel: NSObject, ObservableObject, UIDocumentPickerDelegate {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ICS-Generator", category: "EventViewModel")
    
    @Published var events: [ICSEvent] = []
    @Published var errorMessage: String?
    @Published var showError = false
    
    // UI State
    @Published var selectedEvent: ICSEvent?
    @Published var editingEvent: ICSEvent?
    @Published var eventToDelete: ICSEvent?
    @Published var showingNewEventSheet = false
    @Published var showingEditSheet = false
    @Published var showingSettings = false
    @Published var showingImportSheet = false
    @Published var showingValidatorSheet = false
    @Published var showingDeleteConfirmation = false
    @Published var showingExportOptions = false
    @Published var previewContent: String = ""
    @Published var isSharePresented = false
    @Published var shareURL: URL?
    @Published var shareItems: [Any] = []
    @Published var isShareSheetPresented = false
    
    private var currentViewController: UIViewController?
    private var tempFiles: [URL] = []
    
    override init() {
        super.init()
        loadEvents()
    }
    
    public func loadEvents() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            logger.info("Running in preview mode - skipping UserDefaults load")
            return
        }
        #endif
        
        logger.info("Loading events from UserDefaults")
        if let data = UserDefaults.standard.data(forKey: "events") {
            do {
                let decodedEvents = try JSONDecoder().decode([ICSEvent].self, from: data)
                self.events = decodedEvents
                logger.info("Successfully loaded \(self.events.count) events")
            } catch {
                logger.error("Failed to decode events: \(error.localizedDescription)")
                handleError(error)
            }
        } else {
            logger.info("No events found in UserDefaults")
        }
    }
    
    // MARK: - CRUD Operations
    
    func addEvent(_ event: ICSEvent) {
        logger.info("Adding new event: \(event.title)")
        self.events.append(event)
        logger.info("Event added successfully, total events: \(self.events.count)")
        self.saveEvents()
        self.objectWillChange.send() // Benachrichtigt UI über Änderungen
    }
    
    func updateEvent(_ oldEvent: ICSEvent, _ newEvent: ICSEvent) {
        logger.info("Updating event: \(oldEvent.title) with new event: \(newEvent.title)")
        if let index = self.events.firstIndex(where: { $0.id == oldEvent.id }) {
            logger.info("Found event at index: \(index)")
            self.events[index] = newEvent
            self.saveEvents()
            self.objectWillChange.send()
        } else {
            logger.error("Failed to update event: Event not found with id \(oldEvent.id)")
        }
    }
    
    func deleteEvent(_ event: ICSEvent) {
        self.eventToDelete = event
        self.showingDeleteConfirmation = true
    }
    
    func confirmDelete() {
        guard let event = eventToDelete else { return }
        
        logger.info("Deleting event: \(event.title) with id: \(event.id)")
        let countBefore = self.events.count
        self.events.removeAll { $0.id == event.id }
        let countAfter = self.events.count
        logger.info("Events before: \(countBefore), after: \(countAfter)")
        self.saveEvents()
        self.objectWillChange.send()
        
        self.eventToDelete = nil
        self.showingDeleteConfirmation = false
    }
    
    func cancelDelete() {
        self.eventToDelete = nil
        self.showingDeleteConfirmation = false
    }
    
    private func saveEvents() {
        logger.info("Starting saveEvents() with \(self.events.count) events")
        do {
            let data = try JSONEncoder().encode(self.events)
            UserDefaults.standard.set(data, forKey: "events")
            logger.info("Successfully saved \(self.events.count) events to UserDefaults")
        } catch {
            logger.error("Failed to save events: \(error.localizedDescription)")
            self.errorMessage = "Fehler beim Speichern der Termine"
            self.showError = true
        }
    }
    
    func editEvent(_ event: ICSEvent) {
        self.editingEvent = event
        self.showingEditSheet = true
    }
    
    func duplicateEvent(_ event: ICSEvent) {
        let newEvent = event.duplicated()
        self.addEvent(newEvent)
    }
    
    // MARK: - Export
    
    func exportToString(events: [ICSEvent] = []) -> String {
        self.generateICSString(for: events.isEmpty ? self.events : events)
    }
    
    private func generateICSString(for events: [ICSEvent]) -> String {
        var components = [String]()
        
        components.append("BEGIN:VCALENDAR")
        components.append("VERSION:2.0")
        components.append("PRODID:-//ICS Generator//DE")
        components.append("CALSCALE:GREGORIAN")
        components.append("METHOD:PUBLISH")
        
        for event in events {
            components.append("BEGIN:VEVENT")
            components.append("UID:\(event.id.uuidString)")
            components.append("DTSTAMP:\(self.formatICSDate(Date()))")
            components.append("DTSTART:\(self.formatICSDate(event.startDate))")
            components.append("DTEND:\(self.formatICSDate(event.endDate))")
            components.append("SUMMARY:\(event.title)")
            
            if let location = event.location {
                components.append("LOCATION:\(location)")
            }
            
            if let url = event.url {
                components.append("URL:\(url)")
            }
            
            if let notes = event.notes {
                components.append("DESCRIPTION:\(notes)")
            }
            
            components.append("END:VEVENT")
        }
        
        components.append("END:VCALENDAR")
        return components.joined(separator: "\r\n")
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.showError = true
        }
    }
    
    // MARK: - Import
    
    func importICSString(_ icsString: String) {
        guard let event = ICSEvent.from(icsString: icsString) else {
            let error = NSError(domain: "ICS Import", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültiges ICS-Format"])
            logger.error("Failed to import ICS string: \(error.localizedDescription)")
            handleError(error)
            return
        }
        self.addEvent(event)
    }
    
    // MARK: - Helper Methods
    
    private func formatICSDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
    
    private func cleanupTempFiles() {
        let fileManager = FileManager.default
        self.tempFiles.forEach { url in
            try? fileManager.removeItem(at: url)
        }
        self.tempFiles.removeAll()
    }
    
    private func generateUniqueFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        return "events-\(timestamp)"
    }
    
    func setViewController(_ viewController: UIViewController) {
        self.currentViewController = viewController
    }
    
    deinit {
        self.cleanupTempFiles()
    }
}

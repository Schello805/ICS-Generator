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
    @Published var showingNewEventSheet = false
    @Published var showingEditSheet = false
    @Published var showingSettings = false
    @Published var showingExportOptions = false
    @Published var showingImportSheet = false
    @Published var showingValidatorSheet = false
    @Published var showingDeleteConfirmation = false
    
    // Share State
    @Published var shareItems: [Any] = []
    @Published var isShareSheetPresented = false
    
    // Export States
    @Published var isExporting = false
    @Published var showingPreview = false
    @Published var previewContent: String = ""
    @Published var shareURL: URL?
    @Published var isSharePresented = false
    @Published var exportFeedback: (show: Bool, success: Bool, message: String) = (false, false, "")
    
    private var currentViewController: UIViewController?
    private var tempFiles: [URL] = []
    
    override init() {
        super.init()
        loadEvents()
    }
    
    public func loadEvents() {
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
    
    public func saveEvents() {
        logger.info("Saving \(self.events.count) events to UserDefaults")
        do {
            let encodedData = try JSONEncoder().encode(self.events)
            UserDefaults.standard.set(encodedData, forKey: "events")
            logger.info("Successfully saved events")
        } catch {
            logger.error("Failed to encode events: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func addEvent(_ event: ICSEvent) {
        logger.info("Adding new event: \(event.title)")
        self.events.append(event)
        saveEvents()
    }
    
    func updateEvent(_ event: ICSEvent) {
        logger.info("Updating event: \(event.title)")
        if let index = self.events.firstIndex(where: { $0.id == event.id }) {
            self.events[index] = event
            saveEvents()
            logger.info("Successfully updated event")
        } else {
            let error = NSError(domain: "EventViewModel", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Event nicht gefunden",
                NSLocalizedFailureReasonErrorKey: "Der zu aktualisierende Termin konnte nicht gefunden werden."
            ])
            logger.error("Failed to update event: Event not found with id \(event.id)")
            handleError(error)
        }
    }
    
    func deleteEvent(_ event: ICSEvent) {
        logger.info("Deleting event: \(event.title)")
        self.events.removeAll { $0.id == event.id }
        saveEvents()
    }
    
    func deleteAllEvents() {
        self.events.removeAll()
        saveEvents()
    }
    
    func editEvent(_ event: ICSEvent) {
        self.editingEvent = event
        self.showingEditSheet = true
    }
    
    func duplicateEvent(_ event: ICSEvent) {
        let newEvent = event.duplicated()
        self.addEvent(newEvent)
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
    
    // MARK: - Export
    
    func exportToString(events: [ICSEvent] = []) -> String {
        self.generateICSString(for: events.isEmpty ? self.events : events)
    }
    
    func exportDirectly(events: [ICSEvent] = []) {
        let eventsToExport = events.isEmpty ? self.events : events
        let icsString = self.generateICSString(for: eventsToExport)
        
        // Erstelle temporäre Datei
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "events.ics"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try icsString.write(to: fileURL, atomically: true, encoding: .utf8)
            self.tempFiles.append(fileURL)
            
            // Zeige Share Sheet
            self.shareURL = fileURL
            self.isSharePresented = true
            
        } catch {
            logger.error("Failed to export events: \(error.localizedDescription)")
            handleError(error)
        }
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
    
    func showExportOptions() {
        do {
            let icsString = try self.generateAndValidateICSString()
            self.previewContent = icsString
            self.showingExportOptions = true
        } catch {
            logger.error("Failed to show export options: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func exportWithPreview() {
        self.isExporting = true
        self.previewContent = self.generateICSString(for: self.events)
        self.showingPreview = true
        self.isExporting = false
    }
    
    private func showExportFeedback(success: Bool, message: String) {
        self.exportFeedback = (show: true, success: success, message: message)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.exportFeedback.show = false
        }
    }
    
    private func generateAndValidateICSString() throws -> String {
        let icsString = self.generateICSString(for: self.events)
        
        // Validiere den ICS-String
        switch ICSValidator.validate(icsString) {
        case .success:
            return icsString
        case .failure(let validationError):
            throw validationError
        }
    }
    
    func confirmExport() {
        self.isExporting = true
        
        Task {
            do {
                try await self.performExport()
                self.showFeedback(success: true, message: String(localized: "Export erfolgreich"))
            } catch {
                logger.error("Failed to confirm export: \(error.localizedDescription)")
                handleError(error)
            }
            
            self.isExporting = false
        }
    }
    
    private func performExport() async throws {
        // Generiere den Dateinamen
        let fileName = self.generateUniqueFileName()
        let tempDirectory = FileManager.default.temporaryDirectory
        let icsFileURL = tempDirectory.appendingPathComponent(fileName).appendingPathExtension("ics")
        
        // Schreibe die Datei
        do {
            try self.previewContent.write(to: icsFileURL, atomically: true, encoding: .utf8)
            self.tempFiles.append(icsFileURL)
            self.shareURL = icsFileURL
            self.isSharePresented = true
        } catch {
            throw error
        }
    }
    
    private func showFeedback(success: Bool, message: String) {
        DispatchQueue.main.async {
            self.exportFeedback = (true, success, message)
            
            // Automatisch ausblenden nach 3 Sekunden
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    self.exportFeedback.show = false
                }
            }
        }
    }
    
    // MARK: - Sharing
    
    func shareEvent(_ event: ICSEvent) {
        logger.info("Sharing event: \(event.title)")
        let icsString = self.generateICSString(for: [event])
        
        do {
            // Erstelle temporäre Datei
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("\(event.title).ics")
            try icsString.write(to: fileURL, atomically: true, encoding: .utf8)
            self.tempFiles.append(fileURL)
            
            // Zeige Share Sheet
            self.shareURL = fileURL
            self.isSharePresented = true
            
            logger.info("Successfully prepared event for sharing")
        } catch {
            logger.error("Failed to share event: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        let icsFileURL = url.appendingPathComponent("events").appendingPathExtension("ics")
        let icsString = self.generateICSString(for: self.events)
        
        do {
            try icsString.write(to: icsFileURL, atomically: true, encoding: .utf8)
            self.isExporting = false
        } catch {
            logger.error("Failed to document picker: \(error.localizedDescription)")
            handleError(error)
        }
    }
    
    func setViewController(_ viewController: UIViewController) {
        self.currentViewController = viewController
    }
    
    deinit {
        self.cleanupTempFiles()
    }
}

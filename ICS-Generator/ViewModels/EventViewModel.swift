import SwiftUI
import UniformTypeIdentifiers
import UIKit

class EventViewModel: NSObject, ObservableObject, UIDocumentPickerDelegate {
    @Published var events: [ICSEvent] = []
    
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
    
    // Error Handling
    @Published var currentError: Error?
    @Published var showingErrorView = false
    
    private var currentViewController: UIViewController?
    private var tempFiles: [URL] = []
    
    override init() {
        super.init()
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
    
    func duplicateEvent(_ event: ICSEvent) {
        let newEvent = event.duplicated()
        addEvent(newEvent)
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
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.currentError = error
            self.showingErrorView = true
        }
    }
    
    func importICSString(_ icsString: String) {
        guard let event = ICSEvent.from(icsString: icsString) else {
            handleError(NSError(domain: "ICS Import", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültiges ICS-Format"]))
            return
        }
        addEvent(event)
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
        exportFeedback = (true, true, String(localized: "Erfolgreich geteilt"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.exportFeedback.show = false
            }
        }
    }
    
    private func formatICSDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
    
    // MARK: - Export Functions
    
    func exportToString() -> String {
        generateICSString(for: events)
    }
    
    func exportDirectly() {
        let icsString = generateICSString(for: events)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("events.ics")
        
        do {
            try icsString.write(to: tempURL, atomically: true, encoding: .utf8)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            print("Error exporting events: \(error)")
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
            components.append("DTSTAMP:\(formatICSDate(Date()))")
            components.append("DTSTART:\(formatICSDate(event.startDate))")
            components.append("DTEND:\(formatICSDate(event.endDate))")
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
    
    @MainActor
    func validateICSString(_ icsString: String) -> Bool {
        guard let _ = ICSEvent.from(icsString: icsString) else {
            return false
        }
        return true
    }
    
    private func cleanupTempFiles() {
        let fileManager = FileManager.default
        tempFiles.forEach { url in
            try? fileManager.removeItem(at: url)
        }
        tempFiles.removeAll()
    }
    
    private func generateUniqueFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        return "events-\(timestamp)"
    }
    
    func showExportOptions() {
        do {
            let icsString = try generateAndValidateICSString()
            previewContent = icsString
            showingExportOptions = true
        } catch {
            handleError(error)
        }
    }
    
    func exportWithPreview() {
        isExporting = true
        previewContent = generateICSString(for: events)
        showingPreview = true
        isExporting = false
    }
    
    private func showExportFeedback(success: Bool, message: String) {
        exportFeedback = (show: true, success: success, message: message)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.exportFeedback.show = false
        }
    }
    
    private func generateAndValidateICSString() throws -> String {
        let icsString = generateICSString(for: events)
        
        // Validiere den ICS-String
        switch ICSValidator.validate(icsString) {
        case .success:
            return icsString
        case .failure(let validationError):
            throw validationError
        }
    }
    
    func confirmExport() {
        isExporting = true
        
        Task {
            do {
                try await performExport()
                showFeedback(success: true, message: String(localized: "Export erfolgreich"))
            } catch {
                handleError(error)
            }
            
            isExporting = false
        }
    }
    
    private func performExport() async throws {
        // Generiere den Dateinamen
        let fileName = generateUniqueFileName()
        let tempDirectory = FileManager.default.temporaryDirectory
        let icsFileURL = tempDirectory.appendingPathComponent(fileName).appendingPathExtension("ics")
        
        // Schreibe die Datei
        do {
            try previewContent.write(to: icsFileURL, atomically: true, encoding: .utf8)
            tempFiles.append(icsFileURL)
            shareURL = icsFileURL
            isSharePresented = true
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
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        let icsFileURL = url.appendingPathComponent("events").appendingPathExtension("ics")
        let icsString = generateICSString(for: events)
        
        do {
            try icsString.write(to: icsFileURL, atomically: true, encoding: .utf8)
            isExporting = false
        } catch {
            handleError(error)
        }
    }
    
    func setViewController(_ viewController: UIViewController) {
        self.currentViewController = viewController
    }
    
    deinit {
        cleanupTempFiles()
    }
}

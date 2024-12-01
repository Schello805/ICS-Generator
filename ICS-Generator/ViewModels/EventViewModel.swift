import SwiftUI

class EventViewModel: ObservableObject {
    @Published var events: [ICSEvent] = []
    @Published var showingError = false
    @Published var showingSuccess = false
    var errorMessage: String?
    
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
        showSuccessMessage()
    }
    
    func updateEvent(_ event: ICSEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
            showSuccessMessage()
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
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func showSuccessMessage() {
        showingSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showingSuccess = false
        }
    }
    
    func exportEvent(_ event: ICSEvent) {
        let icsString = event.toICSString()
        
        // Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(event.title.replacingOccurrences(of: " ", with: "_")).ics"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try icsString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Share the file
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // For iPad
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = window
                    popoverController.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            showError("Error exporting event: \(error.localizedDescription)")
        }
    }
    
    func generateICS(for events: [ICSEvent]) -> URL? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "events.ics"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        var icsContent = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//ICS-Generator//DE\r\n"
        
        for event in events {
            icsContent += event.toICSString() + "\r\n"
        }
        
        icsContent += "END:VCALENDAR"
        
        do {
            try icsContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            showError("Fehler beim Erstellen der ICS-Datei: \(error.localizedDescription)")
            return nil
        }
    }
}

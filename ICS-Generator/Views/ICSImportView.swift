import SwiftUI
import UniformTypeIdentifiers

struct ICSImportView: View {
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var importResult: ImportResult?
    @State private var showingSuccessMessage = false
    @State private var isImporting = false
    
    struct ImportResult {
        let success: Bool
        let event: ICSEvent?
        let message: String
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ICS-Datei importieren")
                        .font(.headline)
                    
                    Text("Importieren Sie einen Termin aus einer ICS-Datei in Ihre Terminliste.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ImportFeatureItem(text: "Unterstützt Outlook, Apple Calendar und Google Calendar")
                        ImportFeatureItem(text: "Importiert Titel, Datum, Uhrzeit und Ort")
                        ImportFeatureItem(text: "Erkennt ganztägige Termine")
                        ImportFeatureItem(text: "Übernimmt Notizen und Beschreibungen")
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section {
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.blue)
                        Text("ICS-Datei auswählen")
                    }
                }
                .disabled(isImporting)
            }
            
            if let result = importResult {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.success ? .green : .red)
                            Text(result.message)
                                .font(.headline)
                        }
                        
                        if let event = result.event {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(event.title)
                                    .font(.headline)
                                Text(event.formattedDate)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let location = event.location {
                                    Text(location)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("ICS Import")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "ics")!],
            allowsMultipleSelection: false
        ) { result in
            isImporting = true
            
            switch result {
            case .success(let urls):
                guard let selectedFileURL = urls.first else { return }
                
                guard selectedFileURL.startAccessingSecurityScopedResource() else {
                    importResult = ImportResult(
                        success: false,
                        event: nil,
                        message: "Keine Berechtigung zum Lesen der Datei"
                    )
                    isImporting = false
                    return
                }
                
                defer {
                    selectedFileURL.stopAccessingSecurityScopedResource()
                }
                
                do {
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let tempFileURL = tempDirectory.appendingPathComponent(selectedFileURL.lastPathComponent)
                    
                    if FileManager.default.fileExists(atPath: tempFileURL.path) {
                        try FileManager.default.removeItem(at: tempFileURL)
                    }
                    
                    try FileManager.default.copyItem(at: selectedFileURL, to: tempFileURL)
                    
                    let content = try String(contentsOf: tempFileURL, encoding: .utf8)
                    let lines = content.components(separatedBy: .newlines)
                    
                    var title = ""
                    var startDate: Date?
                    var endDate: Date?
                    var location: String?
                    var notes: String?
                    var isAllDay = false
                    
                    for line in lines {
                        if line.hasPrefix("SUMMARY:") {
                            title = String(line.dropFirst(8))
                        } else if line.hasPrefix("DTSTART") {
                            if line.contains("VALUE=DATE:") {
                                isAllDay = true
                                let dateStr = line.components(separatedBy: ":").last ?? ""
                                startDate = parseICSDate(dateStr, isAllDay: true)
                            } else {
                                let dateStr = line.components(separatedBy: ":").last ?? ""
                                startDate = parseICSDate(dateStr, isAllDay: false)
                            }
                        } else if line.hasPrefix("DTEND") {
                            if line.contains("VALUE=DATE:") {
                                let dateStr = line.components(separatedBy: ":").last ?? ""
                                endDate = parseICSDate(dateStr, isAllDay: true)
                            } else {
                                let dateStr = line.components(separatedBy: ":").last ?? ""
                                endDate = parseICSDate(dateStr, isAllDay: false)
                            }
                        } else if line.hasPrefix("LOCATION:") {
                            location = String(line.dropFirst(9))
                        } else if line.hasPrefix("DESCRIPTION:") {
                            notes = String(line.dropFirst(12))
                        }
                    }
                    
                    guard !title.isEmpty else {
                        importResult = ImportResult(
                            success: false,
                            event: nil,
                            message: "Kein Titel in der ICS-Datei gefunden"
                        )
                        isImporting = false
                        return
                    }
                    
                    guard let start = startDate, let end = endDate else {
                        importResult = ImportResult(
                            success: false,
                            event: nil,
                            message: "Ungültige oder fehlende Datumsangaben"
                        )
                        isImporting = false
                        return
                    }
                    
                    let event = ICSEvent(
                        title: title,
                        startDate: start,
                        endDate: end,
                        isAllDay: isAllDay,
                        location: location,
                        notes: notes
                    )
                    
                    viewModel.addEvent(event)
                    importResult = ImportResult(
                        success: true,
                        event: event,
                        message: "Termin erfolgreich importiert"
                    )
                    
                    // Automatisch schließen nach erfolgreichem Import
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                    
                } catch {
                    importResult = ImportResult(
                        success: false,
                        event: nil,
                        message: "Fehler beim Lesen der Datei: \(error.localizedDescription)"
                    )
                }
                
            case .failure(let error):
                importResult = ImportResult(
                    success: false,
                    event: nil,
                    message: "Fehler beim Auswählen der Datei: \(error.localizedDescription)"
                )
            }
            
            isImporting = false
        }
        .overlay {
            if isImporting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Importiere Termin...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    }
            }
        }
    }
    
    private func parseICSDate(_ dateString: String, isAllDay: Bool) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if isAllDay {
            formatter.dateFormat = "yyyyMMdd"
        } else {
            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        }
        
        return formatter.date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

struct ImportFeatureItem: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.subheadline)
        }
    }
}

import SwiftUI
import UniformTypeIdentifiers
import os.log

struct ICSPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ICS-Generator", category: "ICSPreviewView")
    
    let icsContent: String
    let events: [ICSEvent]
    @StateObject private var exportSettings = ExportSettings()
    @State private var isSharePresented = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showExportOptions = false
    @State private var showPreview = false
    @State private var exportURL: URL?
    
    private func validateAndCreateFile() -> Bool {
        // Validiere die ICS-Datei
        switch ICSValidator.validate(icsContent) {
        case .success(let checks):
            let failedChecks = checks.filter { !$0.passed }
            if !failedChecks.isEmpty {
                let errors = failedChecks.map { "\($0.description): \($0.message ?? "")" }.joined(separator: "\n")
                logger.error("ICS validation failed: \(errors)")
                errorMessage = "Validierungsfehler:\n\(errors)"
                showError = true
                return false
            }
            logger.info("ICS validation passed, creating file")
            
        case .failure(let error):
            logger.error("ICS validation error: \(error.localizedDescription)")
            errorMessage = "Validierungsfehler: \(error.localizedDescription)"
            showError = true
            return false
        }
        
        // Erstelle temporäre Datei
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = generateFilename()
            let fileURL = tempDir.appendingPathComponent(fileName).appendingPathExtension("ics")
            
            // Lösche existierende Datei, falls vorhanden
            try? FileManager.default.removeItem(at: fileURL)
            
            // Schreibe den Inhalt
            try icsContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            logger.info("Successfully created ICS file at: \(fileURL.path)")
            exportURL = fileURL
            return true
        } catch {
            logger.error("Error creating ICS file: \(error.localizedDescription)")
            errorMessage = "Fehler beim Erstellen der Datei: \(error.localizedDescription)"
            showError = true
            return false
        }
    }
    
    private func generateFilename() -> String {
        return exportSettings.generateFilename(for: events)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if showPreview {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ICS Vorschau")
                                .font(.title2)
                                .bold()
                                .padding(.horizontal)
                            
                            Button(action: {
                                showPreview = false
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Zurück zur Auswahl")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                            }
                            
                            Text(icsContent)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(CustomColors.secondaryBackground)
                                .cornerRadius(12)
                            
                            Button(action: {
                                showPreview = false
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Zurück zur Auswahl")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        Text("ICS Export")
                            .font(.title2)
                            .bold()
                        
                        Text("Wählen Sie eine Option:")
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                showPreview = true
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                    Text("ICS-Datei anzeigen")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                if validateAndCreateFile() {
                                    isSharePresented = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("ICS-Datei teilen")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
                
                if showPreview {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            if validateAndCreateFile() {
                                isSharePresented = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $isSharePresented) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Fehler", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    ICSPreviewView(icsContent: """
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//ICS Generator//DE
    BEGIN:VEVENT
    SUMMARY:Test Event
    DTSTART:20231225T090000Z
    DTEND:20231225T100000Z
    END:VEVENT
    END:VCALENDAR
    """, events: [])
}

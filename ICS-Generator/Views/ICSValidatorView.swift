import SwiftUI
import UniformTypeIdentifiers

struct ICSValidatorView: View {
    @EnvironmentObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var validationResult: ValidationResult?
    @State private var isValidating = false
    
    struct ValidationResult {
        struct Check {
            let name: String
            let passed: Bool
            let message: String?
        }
        
        let checks: [Check]
        var isValid: Bool {
            checks.allSatisfy { $0.passed }
        }
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ICS-Datei Validator")
                        .font(.headline)
                    
                    Text("Der Validator prüft Ihre ICS-Datei auf Standardkonformität und Kompatibilität.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.gearshape")
                            .foregroundColor(.blue)
                        Text("ICS-Datei prüfen")
                    }
                }
                .disabled(isValidating)
            }
            
            if let result = validationResult {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        // Gesamtergebnis
                        HStack {
                            Image(systemName: result.isValid ? "checkmark.seal.fill" : "xmark.seal.fill")
                                .foregroundColor(result.isValid ? .green : .red)
                                .font(.title2)
                            Text(result.isValid ? "ICS-Datei ist gültig" : "ICS-Datei ist ungültig")
                                .font(.headline)
                        }
                        .padding(.vertical, 4)
                        
                        // Einzelne Prüfungen
                        ForEach(result.checks, id: \.name) { check in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: check.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(check.passed ? .green : .red)
                                    Text(check.name)
                                        .font(.subheadline)
                                }
                                if let message = check.message {
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 28)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("ICS Validator")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "ics")!],
            allowsMultipleSelection: false
        ) { result in
            isValidating = true
            
            switch result {
            case .success(let urls):
                guard let selectedFileURL = urls.first else { return }
                
                guard selectedFileURL.startAccessingSecurityScopedResource() else {
                    validationResult = ValidationResult(checks: [
                        .init(name: "Dateizugriff", passed: false, message: "Keine Berechtigung zum Lesen der Datei")
                    ])
                    isValidating = false
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
                    
                    var checks = [ValidationResult.Check]()
                    
                    // 1. Grundlegende Dateistruktur
                    let hasVCalendar = lines.contains("BEGIN:VCALENDAR") && lines.contains("END:VCALENDAR")
                    checks.append(.init(
                        name: "ICS Dateistruktur",
                        passed: hasVCalendar,
                        message: hasVCalendar ? nil : "BEGIN:VCALENDAR oder END:VCALENDAR fehlt"
                    ))
                    
                    // 2. Version und Produkt-ID
                    let hasVersion = lines.contains { $0.hasPrefix("VERSION:") }
                    checks.append(.init(
                        name: "Version",
                        passed: hasVersion,
                        message: hasVersion ? nil : "VERSION-Angabe fehlt"
                    ))
                    
                    // 3. Event-Struktur
                    let hasEventStart = lines.contains("BEGIN:VEVENT")
                    let hasEventEnd = lines.contains("END:VEVENT")
                    let validEventStructure = hasEventStart && hasEventEnd
                    checks.append(.init(
                        name: "Event-Struktur",
                        passed: validEventStructure,
                        message: validEventStructure ? nil : "BEGIN:VEVENT oder END:VEVENT fehlt"
                    ))
                    
                    // 4. Pflichtfelder
                    var missingFields = [String]()
                    let requiredFields = ["SUMMARY:", "DTSTART", "DTEND"]
                    let hasRequiredFields = requiredFields.allSatisfy { field in
                        let hasField = lines.contains { $0.hasPrefix(field) }
                        if !hasField {
                            missingFields.append(field.replacingOccurrences(of: ":", with: ""))
                        }
                        return hasField
                    }
                    checks.append(.init(
                        name: "Pflichtfelder",
                        passed: hasRequiredFields,
                        message: hasRequiredFields ? nil : "Fehlende Felder: \(missingFields.joined(separator: ", "))"
                    ))
                    
                    // 5. Datumsformat
                    var invalidDates = [String]()
                    for line in lines {
                        if line.hasPrefix("DTSTART") || line.hasPrefix("DTEND") {
                            let isAllDay = line.contains("VALUE=DATE:")
                            let dateStr = line.components(separatedBy: ":").last ?? ""
                            if parseICSDate(dateStr, isAllDay: isAllDay) == nil {
                                invalidDates.append(line.prefix(7).description)
                            }
                        }
                    }
                    let validDates = invalidDates.isEmpty
                    checks.append(.init(
                        name: "Datumsformate",
                        passed: validDates,
                        message: validDates ? nil : "Ungültige Datumsformate in: \(invalidDates.joined(separator: ", "))"
                    ))
                    
                    // 6. Optionale Felder
                    var foundOptionalFields = [String]()
                    let optionalFields = ["LOCATION:", "DESCRIPTION:", "RRULE:", "CATEGORIES:"]
                    for field in optionalFields {
                        if lines.contains(where: { $0.hasPrefix(field) }) {
                            foundOptionalFields.append(field.replacingOccurrences(of: ":", with: ""))
                        }
                    }
                    checks.append(.init(
                        name: "Optionale Felder",
                        passed: true,
                        message: foundOptionalFields.isEmpty ? "Keine optionalen Felder gefunden" : "Gefunden: \(foundOptionalFields.joined(separator: ", "))"
                    ))
                    
                    validationResult = ValidationResult(checks: checks)
                    
                } catch {
                    validationResult = ValidationResult(checks: [
                        .init(name: "Dateizugriff", passed: false, message: "Fehler beim Lesen der Datei: \(error.localizedDescription)")
                    ])
                }
                
            case .failure(let error):
                validationResult = ValidationResult(checks: [
                    .init(name: "Dateizugriff", passed: false, message: "Fehler beim Auswählen der Datei: \(error.localizedDescription)")
                ])
            }
            
            isValidating = false
        }
        .overlay {
            if isValidating {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Prüfe ICS-Datei...")
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

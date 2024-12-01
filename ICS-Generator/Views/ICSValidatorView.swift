import SwiftUI
import UniformTypeIdentifiers

struct ICSValidatorView: View {
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var validationResult: ValidationResult?
    @State private var showingValidationResult = false
    @State private var isValidating = false
    
    struct ValidationResult {
        let isValid: Bool
        let details: [String]
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ICS-Datei Validator")
                        .font(.headline)
                    
                    Text("Hier können Sie ICS-Dateien auf ihre Gültigkeit überprüfen. Der Validator prüft die Datei auf:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ValidatorCheckItem(text: "Erforderliche ICS-Felder")
                        ValidatorCheckItem(text: "Korrekte Datums- und Zeitformate")
                        ValidatorCheckItem(text: "Gültige Ereignisstruktur")
                        ValidatorCheckItem(text: "Standard-Konformität")
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section {
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.arrow.up")
                            .foregroundColor(.blue)
                        Text("ICS-Datei auswählen")
                    }
                }
            }
            
            if let result = validationResult {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.isValid ? .green : .red)
                            Text(result.isValid ? "Datei ist gültig" : "Datei ist ungültig")
                                .font(.headline)
                        }
                        
                        if !result.details.isEmpty {
                            ForEach(result.details, id: \.self) { detail in
                                Text("• " + detail)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
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
                guard let url = urls.first else { return }
                
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let lines = content.components(separatedBy: .newlines)
                    var details: [String] = []
                    var isValid = true
                    
                    // Grundlegende Struktur prüfen
                    if !lines.contains("BEGIN:VCALENDAR") {
                        details.append("Fehlender BEGIN:VCALENDAR Tag")
                        isValid = false
                    }
                    if !lines.contains("END:VCALENDAR") {
                        details.append("Fehlender END:VCALENDAR Tag")
                        isValid = false
                    }
                    if !lines.contains(where: { $0.hasPrefix("VERSION:") }) {
                        details.append("Fehlende VERSION")
                        isValid = false
                    }
                    if !lines.contains(where: { $0.hasPrefix("PRODID:") }) {
                        details.append("Fehlende PRODID")
                        isValid = false
                    }
                    
                    // Events prüfen
                    var eventCount = 0
                    var currentEventValid = true
                    var inEvent = false
                    
                    for line in lines {
                        if line == "BEGIN:VEVENT" {
                            inEvent = true
                            eventCount += 1
                            currentEventValid = true
                        } else if line == "END:VEVENT" {
                            inEvent = false
                            if currentEventValid {
                                details.append("Event \(eventCount) ist gültig")
                            }
                        }
                        
                        if inEvent {
                            // Pflichtfelder für Events prüfen
                            let requiredFields = ["UID:", "DTSTAMP:", "DTSTART:"]
                            for field in requiredFields {
                                if !lines.contains(where: { $0.hasPrefix(field) }) {
                                    details.append("Event \(eventCount): Fehlendes Pflichtfeld \(field)")
                                    currentEventValid = false
                                    isValid = false
                                }
                            }
                            
                            // Datumsformat prüfen
                            if let dtstart = lines.first(where: { $0.hasPrefix("DTSTART:") }) {
                                if !isValidICSDate(String(dtstart.dropFirst(8))) {
                                    details.append("Event \(eventCount): Ungültiges DTSTART Format")
                                    currentEventValid = false
                                    isValid = false
                                }
                            }
                        }
                    }
                    
                    if eventCount == 0 {
                        details.append("Keine Events in der Datei gefunden")
                        isValid = false
                    }
                    
                    validationResult = ValidationResult(isValid: isValid, details: details)
                    
                } catch {
                    validationResult = ValidationResult(
                        isValid: false,
                        details: ["Fehler beim Lesen der Datei: \(error.localizedDescription)"]
                    )
                }
                
            case .failure(let error):
                validationResult = ValidationResult(
                    isValid: false,
                    details: ["Fehler beim Öffnen der Datei: \(error.localizedDescription)"]
                )
            }
            
            isValidating = false
        }
        .overlay {
            if isValidating {
                ProgressView("Validiere ICS-Datei...")
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
    }
    
    private func isValidICSDate(_ dateString: String) -> Bool {
        // Prüft ob das Datum dem Format yyyyMMddTHHmmssZ oder yyyyMMdd entspricht
        let fullFormat = "^[0-9]{8}T[0-9]{6}Z$"
        let dateOnlyFormat = "^[0-9]{8}$"
        
        let fullPredicate = NSPredicate(format: "SELF MATCHES %@", fullFormat)
        let dateOnlyPredicate = NSPredicate(format: "SELF MATCHES %@", dateOnlyFormat)
        
        return fullPredicate.evaluate(with: dateString) || dateOnlyPredicate.evaluate(with: dateString)
    }
}

struct ValidatorCheckItem: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .imageScale(.small)
            Text(text)
                .font(.subheadline)
        }
    }
}

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var ics: UTType {
        UTType(importedAs: "public.calendar-event")
    }
}

struct CustomColors {
    static let background = Color("Background")
    static let secondaryBackground = Color("SecondaryBackground")
    static let tertiaryBackground = Color("TertiaryBackground")
    static let text = Color("Text")
    static let secondaryText = Color("SecondaryText")
    static let accent = Color.accentColor
    
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
}

struct ICSValidatorView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedFile: URL?
    @State private var validationResults: [ValidationCheck] = []
    @State private var isValidating = false
    @State private var showFilePicker = false
    @State private var errorMessage: String?
    @State private var showInfo = true
    @State private var progress: Double = 0
    @State private var currentOperation: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ICS Validator")
                            .font(.title)
                            .bold()
                            .foregroundColor(CustomColors.text)
                        Text("Überprüfen Sie Ihre ICS-Datei auf Standardkonformität")
                            .font(.subheadline)
                            .foregroundColor(CustomColors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    if showInfo {
                        InfoView()
                            .transition(.opacity)
                    }
                    
                    // Dateiauswahl
                    VStack(spacing: 12) {
                        if let selectedFile = selectedFile {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(CustomColors.accent)
                                Text(selectedFile.lastPathComponent)
                                    .lineLimit(1)
                                    .foregroundColor(CustomColors.text)
                                Spacer()
                                Button(action: { self.selectedFile = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(CustomColors.secondaryText)
                                }
                            }
                            .padding()
                            .background(CustomColors.secondaryBackground)
                            .cornerRadius(10)
                        } else {
                            Button(action: { showFilePicker = true }) {
                                HStack {
                                    Image(systemName: "doc.badge.plus")
                                        .font(.title2)
                                    Text("ICS-Datei auswählen")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(CustomColors.accent)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if isValidating {
                        VStack(spacing: 16) {
                            ProgressView(currentOperation)
                                .progressViewStyle(CircularProgressViewStyle(tint: CustomColors.accent))
                            
                            // Fortschrittsbalken
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(CustomColors.secondaryBackground)
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    
                                    Rectangle()
                                        .fill(CustomColors.accent)
                                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                                        .cornerRadius(4)
                                }
                            }
                            .frame(height: 8)
                            
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .foregroundColor(CustomColors.secondaryText)
                        }
                        .padding()
                    } else if !validationResults.isEmpty {
                        // Validierungsergebnisse
                        VStack(alignment: .leading, spacing: 20) {
                            ValidationSummaryView(results: validationResults)
                                .padding(.bottom)
                            
                            ForEach(ValidationCategory.allCases, id: \.self) { category in
                                let categoryResults = validationResults.filter { $0.category == category }
                                if !categoryResults.isEmpty {
                                    ValidationCategoryView(category: category, results: categoryResults)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(CustomColors.error)
                            .padding()
                    }
                }
            }
            .background(CustomColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { withAnimation { showInfo.toggle() } }) {
                        Image(systemName: showInfo ? "info.circle.fill" : "info.circle")
                            .foregroundColor(CustomColors.accent)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.ics, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let selectedURL = try result.get().first else {
                errorMessage = "Keine Datei ausgewählt"
                return
            }
            
            // Sicherstellen, dass wir Zugriff auf die Datei haben
            if !selectedURL.startAccessingSecurityScopedResource() {
                errorMessage = "Zugriff auf die Datei wurde verweigert"
                return
            }
            
            defer {
                selectedURL.stopAccessingSecurityScopedResource()
            }
            
            // Datei in App-Dokumente kopieren für dauerhaften Zugriff
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsDirectory.appendingPathComponent(selectedURL.lastPathComponent)
            
            try? FileManager.default.removeItem(at: destinationURL) // Alte Version löschen falls vorhanden
            
            do {
                try FileManager.default.copyItem(at: selectedURL, to: destinationURL)
                self.selectedFile = destinationURL
                validateFile()
            } catch {
                errorMessage = "Fehler beim Kopieren der Datei: \(error.localizedDescription)"
            }
        } catch {
            errorMessage = "Fehler beim Importieren: \(error.localizedDescription)"
        }
    }
    
    private func validateFile() {
        isValidating = true
        errorMessage = nil
        progress = 0
        currentOperation = "Lese Datei..."
        
        // Datei einlesen und validieren
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: self.selectedFile!, encoding: .utf8)
                
                // Simuliere Fortschritt für verschiedene Validierungsschritte
                DispatchQueue.main.async {
                    progress = 0.2
                    currentOperation = "Prüfe Struktur..."
                }
                Thread.sleep(forTimeInterval: 0.5)
                
                DispatchQueue.main.async {
                    progress = 0.4
                    currentOperation = "Validiere Inhalte..."
                }
                Thread.sleep(forTimeInterval: 0.5)
                
                DispatchQueue.main.async {
                    progress = 0.6
                    currentOperation = "Prüfe Formatierung..."
                }
                Thread.sleep(forTimeInterval: 0.5)
                
                DispatchQueue.main.async {
                    progress = 0.8
                    currentOperation = "Erstelle Bericht..."
                }
                
                switch ICSValidator.validate(content) {
                case .success(let results):
                    DispatchQueue.main.async {
                        progress = 1.0
                        currentOperation = "Fertig!"
                        validationResults = results
                        isValidating = false
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        progress = 1.0
                        validationResults = [
                            ValidationCheck(
                                type: "Fehler",
                                description: "Validierungsfehler",
                                passed: false,
                                message: error.localizedDescription,
                                category: .allgemein
                            )
                        ]
                        isValidating = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Die Datei konnte nicht gelesen werden: \(error.localizedDescription)"
                    validationResults = []
                    isValidating = false
                }
            }
        }
    }
}

struct InfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Über den ICS Validator")
                .font(.headline)
            
            Text("Der ICS Validator hilft Ihnen, Ihre Kalenderdateien auf Kompatibilität und Standardkonformität zu prüfen. Dies ist besonders wichtig, wenn Sie:")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(icon: "calendar", text: "Termine mit anderen teilen möchten")
                InfoRow(icon: "arrow.up.doc", text: "Kalenderdaten importieren")
                InfoRow(icon: "exclamationmark.triangle", text: "Probleme beim Kalenderimport beheben")
            }
            
            Text("Folgende Aspekte werden geprüft:")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 12) {
                CategoryInfoRow(
                    icon: "checkmark.shield",
                    title: "Grundlegende Struktur",
                    description: "Korrekte Formatierung, Version und Pflichtfelder"
                )
                
                CategoryInfoRow(
                    icon: "text.justify",
                    title: "Formatierung",
                    description: "Zeichenkodierung, Zeilenlängen und Syntax"
                )
                
                CategoryInfoRow(
                    icon: "doc.text",
                    title: "Inhalt",
                    description: "Datumsformate, Zeitzonen, Wiederholungen"
                )
                
                CategoryInfoRow(
                    icon: "person.2",
                    title: "Teilnehmer",
                    description: "Korrekte E-Mail-Adressen und Teilnehmerdetails"
                )
                
                CategoryInfoRow(
                    icon: "bell",
                    title: "Erinnerungen",
                    description: "Gültige Alarmeinstellungen und Trigger"
                )
            }
        }
        .padding()
        .background(CustomColors.tertiaryBackground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(CustomColors.accent)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

struct CategoryInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(CustomColors.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ValidationSummaryView: View {
    let results: [ValidationCheck]
    
    private var passedChecks: Int {
        results.filter { $0.passed }.count
    }
    
    private var totalChecks: Int {
        results.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Validierungsergebnis")
                .font(.headline)
            
            HStack(spacing: 20) {
                ValidationStatView(
                    icon: "checkmark.circle.fill",
                    color: CustomColors.success,
                    title: "Erfolgreich",
                    count: passedChecks
                )
                
                ValidationStatView(
                    icon: "xmark.circle.fill",
                    color: CustomColors.error,
                    title: "Fehlgeschlagen",
                    count: totalChecks - passedChecks
                )
            }
        }
    }
}

struct ValidationStatView: View {
    let icon: String
    let color: Color
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(count)")
                    .font(.title2)
                    .bold()
            }
        }
    }
}

struct ValidationCategoryView: View {
    let category: ValidationCategory
    let results: [ValidationCheck]
    @State private var isExpanded = true
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(results) { result in
                        ValidationResultRow(result: result)
                        
                        if result.id != results.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 8)
            },
            label: {
                HStack {
                    Image(systemName: getCategoryIcon(for: category))
                        .foregroundColor(CustomColors.accent)
                    
                    Text(category.rawValue)
                        .font(.headline)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        let passedCount = results.filter { $0.passed }.count
                        Text("\(passedCount)/\(results.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(getCategoryColor(passed: passedCount, total: results.count))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        )
    }
    
    private func getCategoryIcon(for category: ValidationCategory) -> String {
        switch category {
        case .allgemein: return "checkmark.shield"
        case .struktur: return "text.justify"
        case .format: return "doc.text"
        case .inhalt: return "calendar"
        case .teilnehmer: return "person.2"
        case .erinnerungen: return "bell"
        }
    }
    
    private func getCategoryColor(passed: Int, total: Int) -> Color {
        let ratio = Double(passed) / Double(total)
        switch ratio {
        case 1.0: return CustomColors.success
        case 0.5..<1.0: return CustomColors.warning
        default: return CustomColors.error
        }
    }
}

struct ValidationResultRow: View {
    let result: ValidationCheck
    @State private var showSolution = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.passed ? CustomColors.success : CustomColors.error)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.description)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    if let message = result.message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !result.passed {
                        Button(action: { withAnimation { showSolution.toggle() } }) {
                            HStack {
                                Text(showSolution ? "Lösung ausblenden" : "Lösung anzeigen")
                                    .font(.caption)
                                Image(systemName: showSolution ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(CustomColors.accent)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            
            if showSolution && !result.passed {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lösungsvorschlag:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    getSolutionView(for: result)
                }
                .padding()
                .background(CustomColors.tertiaryBackground)
                .cornerRadius(8)
            }
        }
    }
    
    @ViewBuilder
    private func getSolutionView(for result: ValidationCheck) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch result.type {
            case "Encoding":
                Text("• Speichern Sie die Datei im UTF-8 Format")
                Text("• Vermeiden Sie Sonderzeichen außerhalb des ASCII-Bereichs")
                Text("• Prüfen Sie die Zeichenkodierung in Ihrem Editor")
                
            case "LineWrapping":
                Text("• Kürzen Sie lange Zeilen auf maximal 75 Zeichen")
                Text("• Verwenden Sie Zeilenumbrüche nach RFC 5545")
                Text("• Nutzen Sie Fortsetzungszeilen mit Leerzeichen")
                
            case "Structure":
                Text("• Stellen Sie sicher, dass BEGIN und END Paare korrekt sind")
                Text("• Prüfen Sie die Einrückung der Komponenten")
                Text("• Achten Sie auf die richtige Reihenfolge der Elemente")
                
            case "DateTime":
                Text("• Verwenden Sie das Format: YYYYMMDDTHHMMSSZ")
                Text("• Geben Sie die Zeitzone korrekt an")
                Text("• Prüfen Sie Start- und Endzeiten auf Plausibilität")
                
            case "Required":
                Text("• Fügen Sie fehlende Pflichtfelder hinzu")
                Text("• Prüfen Sie die UID auf Eindeutigkeit")
                Text("• Stellen Sie sicher, dass DTSTAMP vorhanden ist")
                
            default:
                Text("• Prüfen Sie die Dokumentation für Details")
                Text("• Validieren Sie gegen den iCalendar Standard")
                Text("• Kontaktieren Sie den Support bei Fragen")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

// Erweiterung für ValidationCategory
extension ValidationCategory: CaseIterable {
    public static var allCases: [ValidationCategory] = [
        .allgemein,
        .struktur,
        .format,
        .inhalt,
        .teilnehmer,
        .erinnerungen
    ]
}

import SwiftUI

struct ExportSettingsView: View {
    @StateObject private var settings = ExportSettings()
    @State private var showingVariableList = false
    @State private var selectedRange: NSRange?
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        Form {
            Section(header: Text("Dateiname für Export")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Dateiname", text: $settings.filenameTemplate)
                            .font(.system(.body, design: .monospaced))
                            .focused($isTextFieldFocused)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onDrop(of: [.text], delegate: TextDropDelegate(text: $settings.filenameTemplate))
                        
                        Button(action: {
                            showingVariableList = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Text("Beispiel: \(settings.generateFilename(for: previewEvents))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Verfügbare Variablen")) {
                ForEach(ExportVariable.allCases, id: \.self) { variable in
                    HStack {
                        Text(variable.rawValue)
                            .font(.system(.body, design: .monospaced))
                            .draggable(variable.rawValue)
                        Text("+")
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Text(variable.description)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(footer: Text("Variablen werden beim Export durch die tatsächlichen Werte ersetzt. Ziehen Sie die Variablen per Drag & Drop in das Textfeld. Das Plus-Zeichen (+) wird automatisch hinzugefügt.")) {
                EmptyView()
            }
        }
        .navigationTitle("Export Einstellungen")
    }
    
    // Beispiel-Events für die Vorschau
    private var previewEvents: [ICSEvent] {
        let now = Date()
        return [
            ICSEvent(
                id: UUID(),
                title: "Beispiel-Termin",
                startDate: now,
                endDate: now.addingTimeInterval(3600),
                isAllDay: false,
                location: "Beispiel-Ort",
                notes: "Dies ist ein Beispiel-Termin",
                url: "https://example.com",
                alert: .fifteenMinutes,
                secondAlert: .none,
                travelTime: 0,
                recurrence: .none,
                customRecurrence: nil,
                attachments: []
            )
        ]
    }
}

struct TextDropDelegate: DropDelegate {
    @Binding var text: String
    
    func performDrop(info: DropInfo) -> Bool {
        if let itemProvider = info.itemProviders(for: [.text]).first {
            _ = itemProvider.loadObject(ofClass: String.self) { string, _ in
                if let stringValue = string {
                    DispatchQueue.main.async {
                        // Füge ein + hinzu, wenn der Text nicht leer ist und nicht mit + endet
                        if !self.text.isEmpty && !self.text.hasSuffix("+") {
                            self.text += "+"
                        }
                        self.text += stringValue
                    }
                }
            }
            return true
        }
        return false
    }
}

#Preview {
    NavigationStack {
        ExportSettingsView()
    }
}

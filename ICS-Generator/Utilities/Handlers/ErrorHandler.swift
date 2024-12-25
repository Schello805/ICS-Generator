import Foundation
import SwiftUI

struct ErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text(error.localizedDescription)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Mögliche Lösungen:"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                let steps = recoverySteps(for: error)
                ForEach(steps, id: \.self) { step in
                    HStack(alignment: .top) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.accentColor)
                        Text(step)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            
            if let retry = retryAction {
                Button(action: retry) {
                    Label(String(localized: "Erneut versuchen"), systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
        }
        .padding()
    }
    
    private func recoverySteps(for error: Error) -> [String] {
        if let validationError = error as? ICSValidator.ValidationError {
            switch validationError {
            case .invalidFormat:
                return [
                    String(localized: "Stellen Sie sicher, dass die ICS-Datei korrekt formatiert ist"),
                    String(localized: "Überprüfen Sie die BEGIN:VCALENDAR und END:VCALENDAR Tags"),
                    String(localized: "Prüfen Sie die Formatierung der Eingaben")
                ]
            case .missingRequiredProperty:
                return [
                    String(localized: "Überprüfen Sie die Pflichtfelder (Titel, Datum)"),
                    String(localized: "Stellen Sie sicher, dass alle erforderlichen Eigenschaften vorhanden sind"),
                    String(localized: "Prüfen Sie die Formatierung der Eingaben")
                ]
            case .invalidPropertyValue:
                return [
                    String(localized: "Überprüfen Sie die Werte der Eigenschaften"),
                    String(localized: "Stellen Sie sicher, dass die Datumsangaben gültig sind"),
                    String(localized: "Prüfen Sie die Formatierung der Eingaben")
                ]
            case .invalidEncoding:
                return [
                    String(localized: "Die Datei enthält ungültige Zeichen"),
                    String(localized: "Stellen Sie sicher, dass nur ASCII-Zeichen verwendet werden"),
                    String(localized: "Speichern Sie die Datei mit UTF-8 Kodierung")
                ]
            case .invalidStructure:
                return [
                    String(localized: "Die Struktur der ICS-Datei ist ungültig"),
                    String(localized: "Überprüfen Sie die Verschachtelung der Komponenten"),
                    String(localized: "Stellen Sie sicher, dass alle BEGIN/END Tags korrekt sind")
                ]
            }
        } else {
            return [
                String(localized: "Überprüfen Sie Ihre Internetverbindung"),
                String(localized: "Stellen Sie sicher, dass genügend Speicherplatz verfügbar ist"),
                String(localized: "Versuchen Sie es später erneut")
            ]
        }
    }
}

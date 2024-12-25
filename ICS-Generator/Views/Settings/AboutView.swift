import SwiftUI

struct AboutView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ICS Generator")
                        .font(.title)
                        .bold()
                    
                    Text("Version 2.0")
                        .foregroundColor(.secondary)
                    
                    Text("Diese App wurde von Michael Schellenberger entwickelt, einem Nicht-Programmierer, der mithilfe des Windsurf Editors und KI-Unterstützung diese moderne iOS-App erstellt hat. Die Entwicklung bis Version 2.0 nahm etwa 16 Stunden in Anspruch.")
                        .padding(.vertical, 8)
                    
                    Text("Der komplette Quellcode ist als Open Source auf GitHub verfügbar:")
                    
                    Link("GitHub Repository",
                         destination: URL(string: "https://github.com/Schello805/ICS-Generator")!)
                        .foregroundColor(.blue)
                }
                .padding()
            }
            
            Section(header: Text("Hauptfunktionen")) {
                FeatureRow(title: "Termine erstellen", description: "Intuitive Benutzeroberfläche für die Terminerstellung mit Unterstützung für Standorte und Erinnerungen")
                FeatureRow(title: "Wiederholungen", description: "Flexible Wiederholungsoptionen - täglich, wöchentlich, monatlich oder jährlich")
                FeatureRow(title: "ICS Import/Export", description: "Importieren und exportieren Sie Ihre Termine im standardkonformen ICS-Format")
                FeatureRow(title: "ICS Validator", description: "Validierung von ICS-Dateien nach RFC 5545 Standard")
            }
            
            Section(header: Text("Benutzerfreundlichkeit")) {
                InfoRow(icon: "moon.fill", text: "Dark Mode unterstützt")
                InfoRow(icon: "iphone", text: "iOS 15 oder neuer")
                InfoRow(icon: "globe.europe.africa.fill", text: "Deutsche Sprache")
                InfoRow(icon: "checkmark.seal.fill", text: "Im App Store verfügbar")
            }
            
            Section(header: Text("Entwicklung")) {
                InfoRow(icon: "swift", text: "SwiftUI Framework")
                InfoRow(icon: "person.fill", text: "M. Schellenberger")
                InfoRow(icon: "clock.fill", text: "~16 Stunden Entwicklung")
                InfoRow(icon: "number", text: "Version 2.0")
            }
            
            Section(header: Text("App Store")) {
                Link(destination: URL(string: "https://apps.apple.com/de/app/ics-generator/id6738963683")!) {
                    HStack {
                        Image(systemName: "app.store")
                        Text("Im App Store ansehen")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                }
            }
            
            Section(header: Text("Danksagung")) {
                Text("Besonderer Dank geht an das Windsurf-Team für die Bereitstellung der KI-gestützten Entwicklungsumgebung, die es auch Nicht-Programmierern ermöglicht, professionelle iOS-Apps zu entwickeln.")
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("Über")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}

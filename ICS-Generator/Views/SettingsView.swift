import SwiftUI
import UniformTypeIdentifiers
import StoreKit

struct SettingsView: View {
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetAlert = false
    @AppStorage("defaultAlert") private var defaultAlert: String = ICSEvent.AlertTime.fifteenMinutes.rawValue
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    NavigationLink {
                        ICSValidatorView(viewModel: viewModel)
                    } label: {
                        Label("ICS Validator", systemImage: "checkmark.shield")
                    }
                }
                
                Section(header: Text("Standard-Einstellungen")) {
                    Picker("Standard-Erinnerung", selection: Binding(
                        get: { ICSEvent.AlertTime(rawValue: defaultAlert) ?? .fifteenMinutes },
                        set: { defaultAlert = $0.rawValue }
                    )) {
                        ForEach(ICSEvent.AlertTime.allCases, id: \.self) { alertTime in
                            Text(alertTimeString(alertTime))
                                .tag(alertTime)
                        }
                    }
                }
                
                Section(header: Text("Daten")) {
                    Button(role: .destructive, action: {
                        showingResetAlert = true
                    }) {
                        Label("Alle Termine löschen", systemImage: "trash")
                    }
                }
                
                Section(header: Text("App-Information")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/yourusername/ICS-Generator")!) {
                        HStack {
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            if #available(iOS 18.0, *) {
                                AppStore.requestReview(in: windowScene)
                            } else {
                                SKStoreReviewController.requestReview(in: windowScene)
                            }
                        }
                    }) {
                        HStack {
                            Text("App bewerten")
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("Hilfe & Support")) {
                    Link(destination: URL(string: "mailto:support@example.com")!) {
                        HStack {
                            Text("Support kontaktieren")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Datenschutzerklärung")
                            Spacer()
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Nutzungsbedingungen")
                            Spacer()
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .alert("Alle Termine löschen?", isPresented: $showingResetAlert) {
                Button("Abbrechen", role: .cancel) {}
                Button("Löschen", role: .destructive) {
                    withAnimation {
                        viewModel.events.removeAll()
                        UserDefaults.standard.removeObject(forKey: "savedEvents")
                    }
                }
            } message: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            }
        }
    }
    
    private func alertTimeString(_ alertTime: ICSEvent.AlertTime) -> String {
        switch alertTime {
        case .none:
            return "Keine"
        case .atTime:
            return "Zur Startzeit"
        case .fiveMinutes:
            return "5 Minuten vorher"
        case .tenMinutes:
            return "10 Minuten vorher"
        case .fifteenMinutes:
            return "15 Minuten vorher"
        case .thirtyMinutes:
            return "30 Minuten vorher"
        case .oneHour:
            return "1 Stunde vorher"
        case .twoHours:
            return "2 Stunden vorher"
        case .oneDay:
            return "1 Tag vorher"
        case .twoDays:
            return "2 Tage vorher"
        case .oneWeek:
            return "1 Woche vorher"
        }
    }
}

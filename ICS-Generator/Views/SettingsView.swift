import SwiftUI
import UniformTypeIdentifiers
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingResetAlert = false
    @AppStorage("defaultAlert") private var defaultAlert: String = ICSEvent.AlertTime.fifteenMinutes.rawValue
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            List {
                Section {
                    NavigationLink {
                        ICSValidatorView()
                            .environmentObject(viewModel)
                    } label: {
                        Label(NSLocalizedString("ICS Validator", comment: "ICS Validator"), systemImage: "checkmark.shield")
                    }
                    
                    NavigationLink {
                        ICSImportView(viewModel: viewModel)
                    } label: {
                        Label(NSLocalizedString("ICS importieren", comment: "ICS Import"), systemImage: "square.and.arrow.down")
                    }
                }
                
                Section(header: Text(NSLocalizedString("Standard-Einstellungen", comment: "Default settings section header"))) {
                    Picker(NSLocalizedString("Standard-Erinnerung", comment: "Default reminder picker"), selection: Binding(
                        get: { ICSEvent.AlertTime(rawValue: defaultAlert) ?? .fifteenMinutes },
                        set: { defaultAlert = $0.rawValue }
                    )) {
                        ForEach(ICSEvent.AlertTime.allCases, id: \.self) { alertTime in
                            Text(alertTimeString(alertTime))
                                .tag(alertTime)
                        }
                    }
                }
                
                Section(header: Text(NSLocalizedString("Daten", comment: "Data section header"))) {
                    Button(role: .destructive, action: {
                        showingResetAlert = true
                    }) {
                        Label(NSLocalizedString("Alle Termine löschen", comment: "Delete all events button"), systemImage: "trash")
                    }
                }
                
                Section(header: Text(NSLocalizedString("App-Information", comment: "App information section header"))) {
                    HStack {
                        Text(NSLocalizedString("Version", comment: "Version"))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/Schello805/ICS-Generator")!) {
                        HStack {
                            Text(NSLocalizedString("GitHub Repository", comment: "GitHub Repository"))
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
                            Text(NSLocalizedString("Rate App", comment: "Rate app button"))
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text(NSLocalizedString("Hilfe & Support", comment: "Help and support section header"))) {
                    Link(destination: URL(string: "mailto:info@schellenberger.biz")!) {
                        HStack {
                            Text(NSLocalizedString("Support kontaktieren", comment: "Contact support button"))
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/Schello805/ICS-generator/blob/iOSApp_ICS-Generator/PRIVACY.md")!) {
                        HStack {
                            Text(NSLocalizedString("Datenschutz", comment: "Privacy policy button"))
                            Spacer()
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/Schello805/ICS-generator/blob/iOSApp_ICS-Generator/README.md")!) {
                        HStack {
                            Text(NSLocalizedString("Nutzungsbedingungen", comment: "Terms of use button"))
                            Spacer()
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(NSLocalizedString("Einstellungen", comment: "Settings title"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(NSLocalizedString("Alle Termine löschen?", comment: "Delete all events alert title"), isPresented: $showingResetAlert) {
                Button(NSLocalizedString("Abbrechen", comment: "Cancel button"), role: .cancel) {}
                Button(NSLocalizedString("Löschen", comment: "Delete button"), role: .destructive) {
                    withAnimation {
                        viewModel.events.removeAll()
                        UserDefaults.standard.removeObject(forKey: "savedEvents")
                    }
                }
            } message: {
                Text(NSLocalizedString("Diese Aktion kann nicht rückgängig gemacht werden.", comment: "Delete all events confirmation"))
            }
        } else {
            NavigationStack {
                Form {
                    Section {
                        NavigationLink {
                            ICSValidatorView()
                                .environmentObject(viewModel)
                        } label: {
                            Label(NSLocalizedString("ICS Validator", comment: "ICS Validator"), systemImage: "checkmark.shield")
                        }
                        
                        NavigationLink {
                            ICSImportView(viewModel: viewModel)
                        } label: {
                            Label(NSLocalizedString("ICS importieren", comment: "ICS Import"), systemImage: "square.and.arrow.down")
                        }
                    }
                    
                    Section(header: Text(NSLocalizedString("Standard-Einstellungen", comment: "Default settings section header"))) {
                        Picker(NSLocalizedString("Standard-Erinnerung", comment: "Default reminder picker"), selection: Binding(
                            get: { ICSEvent.AlertTime(rawValue: defaultAlert) ?? .fifteenMinutes },
                            set: { defaultAlert = $0.rawValue }
                        )) {
                            ForEach(ICSEvent.AlertTime.allCases, id: \.self) { alertTime in
                                Text(alertTimeString(alertTime))
                                    .tag(alertTime)
                            }
                        }
                    }
                    
                    Section(header: Text(NSLocalizedString("Daten", comment: "Data section header"))) {
                        Button(role: .destructive, action: {
                            showingResetAlert = true
                        }) {
                            Label(NSLocalizedString("Alle Termine löschen", comment: "Delete all events button"), systemImage: "trash")
                        }
                    }
                    
                    Section(header: Text(NSLocalizedString("App-Information", comment: "App information section header"))) {
                        HStack {
                            Text(NSLocalizedString("Version", comment: "Version"))
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                                .foregroundColor(.secondary)
                        }
                        
                        Link(destination: URL(string: "https://github.com/Schello805/ICS-Generator")!) {
                            HStack {
                                Text(NSLocalizedString("GitHub Repository", comment: "GitHub Repository"))
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
                                Text(NSLocalizedString("Rate App", comment: "Rate app button"))
                                Spacer()
                                Image(systemName: "star.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Section(header: Text(NSLocalizedString("Hilfe & Support", comment: "Help and support section header"))) {
                        Link(destination: URL(string: "mailto:info@schellenberger.biz")!) {
                            HStack {
                                Text(NSLocalizedString("Support kontaktieren", comment: "Contact support button"))
                                Spacer()
                                Image(systemName: "envelope")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Link(destination: URL(string: "https://github.com/Schello805/ICS-generator/blob/iOSApp_ICS-Generator/PRIVACY.md")!) {
                            HStack {
                                Text(NSLocalizedString("Datenschutz", comment: "Privacy policy button"))
                                Spacer()
                                Image(systemName: "hand.raised")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Link(destination: URL(string: "https://github.com/Schello805/ICS-generator/blob/iOSApp_ICS-Generator/README.md")!) {
                            HStack {
                                Text(NSLocalizedString("Nutzungsbedingungen", comment: "Terms of use button"))
                                Spacer()
                                Image(systemName: "doc.text")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .navigationTitle(NSLocalizedString("Einstellungen", comment: "Settings title"))
                .navigationBarTitleDisplayMode(.inline)
                .alert(NSLocalizedString("Alle Termine löschen?", comment: "Delete all events alert title"), isPresented: $showingResetAlert) {
                    Button(NSLocalizedString("Abbrechen", comment: "Cancel button"), role: .cancel) {}
                    Button(NSLocalizedString("Löschen", comment: "Delete button"), role: .destructive) {
                        withAnimation {
                            viewModel.events.removeAll()
                            UserDefaults.standard.removeObject(forKey: "savedEvents")
                        }
                    }
                } message: {
                    Text(NSLocalizedString("Diese Aktion kann nicht rückgängig gemacht werden.", comment: "Delete all events confirmation"))
                }
            }
        }
    }
    
    private func alertTimeString(_ alertTime: ICSEvent.AlertTime) -> String {
        switch alertTime {
        case .none:
            return NSLocalizedString("Keine", comment: "None")
        case .atTime:
            return NSLocalizedString("Zum Startzeitpunkt", comment: "At Start Time")
        case .fiveMinutes:
            return NSLocalizedString("5 Minuten vorher", comment: "5 Minutes Before")
        case .tenMinutes:
            return NSLocalizedString("10 Minuten vorher", comment: "10 Minutes Before")
        case .fifteenMinutes:
            return NSLocalizedString("15 Minuten vorher", comment: "15 Minutes Before")
        case .thirtyMinutes:
            return NSLocalizedString("30 Minuten vorher", comment: "30 Minutes Before")
        case .oneHour:
            return NSLocalizedString("1 Stunde vorher", comment: "1 Hour Before")
        case .twoHours:
            return NSLocalizedString("2 Stunden vorher", comment: "2 Hours Before")
        case .oneDay:
            return NSLocalizedString("1 Tag vorher", comment: "1 Day Before")
        case .twoDays:
            return NSLocalizedString("2 Tage vorher", comment: "2 Days Before")
        case .oneWeek:
            return NSLocalizedString("1 Woche vorher", comment: "1 Week Before")
        }
    }
}

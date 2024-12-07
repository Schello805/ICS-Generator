import SwiftUI

@main
struct ICSGeneratorApp: App {
    @StateObject private var viewModel: EventViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: EventViewModel())
    }
    
    var body: some Scene {
        #if os(macOS)
        Group {
            WindowGroup {
                ContentView()
                    .environmentObject(viewModel)
                    .frame(minWidth: 600, minHeight: 400)
            }
            .commands {
                CommandGroup(after: .newItem) {
                    Button(NSLocalizedString("Neuer Termin", comment: "Add event menu item")) {
                        viewModel.showingNewEventSheet = true
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    
                    Button(NSLocalizedString("ICS Validator", comment: "ICS validator menu item")) {
                        viewModel.showingValidatorSheet = true
                    }
                    .keyboardShortcut("v", modifiers: [.command, .shift])
                    
                    Button(NSLocalizedString("Einstellungen", comment: "Settings menu item")) {
                        viewModel.showingSettings = true
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
                
                CommandGroup(after: .importExport) {
                    Button(NSLocalizedString("Alle Termine exportieren", comment: "Export all events menu item")) {
                        viewModel.showingExportOptions = true
                    }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
                    
                    Button(NSLocalizedString("ICS importieren", comment: "Import ICS menu item")) {
                        viewModel.showingImportSheet = true
                    }
                    .keyboardShortcut("i", modifiers: [.command, .shift])
                }
                
                CommandGroup(after: .systemServices) {
                    Button(NSLocalizedString("Alle Termine löschen", comment: "Delete all events menu item")) {
                        viewModel.showingDeleteConfirmation = true
                    }
                    .keyboardShortcut(.delete, modifiers: [.command, .shift])
                }
            }
            
            Settings {
                SettingsView()
                    .environmentObject(viewModel)
            }
        }
        #else
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        #endif
    }
}

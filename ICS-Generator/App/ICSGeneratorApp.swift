import SwiftUI

@main
struct ICSGeneratorApp: App {
    @StateObject private var viewModel = EventViewModel()
    
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
                    Button("Neuer Termin") {
                        viewModel.showingNewEventSheet = true
                    }
                    .keyboardShortcut("n", modifiers: .command)
                    
                    Button("ICS Validator") {
                        viewModel.showingValidatorSheet = true
                    }
                    .keyboardShortcut("v", modifiers: [.command, .shift])
                    
                    Button("Einstellungen") {
                        viewModel.showingSettings = true
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
                
                CommandGroup(after: .importExport) {
                    Button("Alle Termine exportieren") {
                        viewModel.showingExportOptions = true
                    }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
                    
                    Button("ICS importieren") {
                        viewModel.showingImportSheet = true
                    }
                    .keyboardShortcut("i", modifiers: [.command, .shift])
                }
                
                CommandGroup(after: .systemServices) {
                    Button("Alle Termine löschen") {
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

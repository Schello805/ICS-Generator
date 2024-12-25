import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var viewModel: EventViewModel
    @Binding var selectedEvent: ICSEvent?
    
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Termin erstellen") {
                viewModel.showingNewEventSheet = true
            }
            .keyboardShortcut("n", modifiers: .command)
            
            if let event = selectedEvent {
                Divider()
                
                Button("Termin bearbeiten") {
                    viewModel.editEvent(event)
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Button("Termin duplizieren") {
                    viewModel.duplicateEvent(event)
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Button("Termin teilen") {
                    viewModel.shareEvent(event)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Termin löschen", role: .destructive) {
                    viewModel.deleteEvent(event)
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
        }
        
        CommandGroup(after: .importExport) {
            Button("Alle Termine exportieren") {
                viewModel.showExportOptions()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            
            Button("ICS-Datei importieren") {
                viewModel.showingImportSheet = true
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
        }
        
        CommandGroup(after: .toolbar) {
            Button("ICS-Validator") {
                viewModel.showingValidatorSheet = true
            }
            .keyboardShortcut("v", modifiers: [.command, .shift])
        }
    }
}

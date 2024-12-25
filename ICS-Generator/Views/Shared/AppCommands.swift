import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var viewModel: EventViewModel
    
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Neuer Termin") {
                viewModel.showingNewEventSheet = true
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("Termin bearbeiten") {
                if let selectedEvent = viewModel.selectedEvent {
                    viewModel.editEvent(selectedEvent)
                }
            }
            .keyboardShortcut("e", modifiers: .command)
            .disabled(viewModel.selectedEvent == nil)
        }
        
        CommandGroup(after: .pasteboard) {
            Button("Als ICS kopieren") {
                if let selectedEvent = viewModel.selectedEvent {
                    Platform.copyToClipboard(selectedEvent.toICSString())
                }
            }
            .keyboardShortcut("c", modifiers: [.command, .option])
            .disabled(viewModel.selectedEvent == nil)
            
            Button("Teilen") {
                if let selectedEvent = viewModel.selectedEvent {
                    viewModel.shareEvent(selectedEvent)
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(viewModel.selectedEvent == nil)
        }
        
        CommandGroup(after: .toolbar) {
            Button("Einstellungen") {
                viewModel.showingSettings = true
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}

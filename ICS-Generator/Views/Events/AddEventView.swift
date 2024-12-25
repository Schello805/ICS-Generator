import SwiftUI

struct AddEventView: View {
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDiscardAlert = false
    
    var body: some View {
        NavigationStack {
            EventEditorView()
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            showingDiscardAlert = true
                        }
                    }
                }
        }
        .alert("Änderungen verwerfen?", isPresented: $showingDiscardAlert) {
            Button("Abbrechen", role: .cancel) { }
            Button("Verwerfen", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Möchten Sie die Änderungen wirklich verwerfen?")
        }
    }
}

struct AddEventView_Previews: PreviewProvider {
    static var previews: some View {
        AddEventView(viewModel: EventViewModel())
    }
}

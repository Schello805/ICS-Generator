import SwiftUI

struct FilterSheetView: View {
    @Binding var selectedFilter: EventFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(EventFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                        dismiss()
                    } label: {
                        HStack {
                            Text(filter.description)
                            Spacer()
                            if filter == selectedFilter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FilterSheetView(selectedFilter: .constant(.all))
}

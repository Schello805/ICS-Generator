import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var location: String
    
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @State private var searchText = ""
    @State private var selectedLocation: MKLocalSearchCompletion?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Ort suchen", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .onChange(of: searchText) { _, newValue in
                            searchCompleter.search(query: newValue)
                        }
                }
                
                Section {
                    ForEach(searchCompleter.completions, id: \.self) { completion in
                        VStack(alignment: .leading) {
                            Text(completion.title)
                                .font(.headline)
                            Text(completion.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .onTapGesture {
                            selectedLocation = completion
                            location = "\(completion.title), \(completion.subtitle)"
                            dismiss()
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Ort auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
    }
}

class LocationSearchCompleter: NSObject, ObservableObject {
    @Published var completions: [MKLocalSearchCompletion] = []
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .pointOfInterest
    }
    
    func search(query: String) {
        searchCompleter.queryFragment = query
    }
}

extension LocationSearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.completions = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search failed with error: \(error.localizedDescription)")
    }
}

#Preview {
    LocationPickerView(location: .constant(""))
}

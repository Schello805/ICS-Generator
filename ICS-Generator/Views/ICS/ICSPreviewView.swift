import SwiftUI

struct ICSPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let icsContent: String
    @State private var isSharePresented = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ICS Vorschau")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    Text(icsContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(CustomColors.secondaryBackground)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isSharePresented = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isSharePresented) {
                if let data = icsContent.data(using: .utf8) {
                    ShareSheet(activityItems: [data])
                }
            }
        }
    }
}

#Preview {
    ICSPreviewView(icsContent: """
    BEGIN:VCALENDAR
    VERSION:2.0
    BEGIN:VEVENT
    SUMMARY:Test Event
    DTSTART:20220101T120000Z
    DTEND:20220101T130000Z
    LOCATION:Test Location
    DESCRIPTION:Test Description
    END:VEVENT
    END:VCALENDAR
    """)
}

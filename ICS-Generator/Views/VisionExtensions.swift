#if os(visionOS)
import SwiftUI

struct VisionOSModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .ornament(
                attachmentAnchor: .scene(.top),
                ornament: {
                    HStack {
                        Text("ICS Generator")
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .frame(width: 300)
                }
            )
            .ornament(
                attachmentAnchor: .scene(.bottom),
                ornament: {
                    HStack {
                        Spacer()
                        Text("Tippen Sie zum Erstellen")
                            .font(.caption)
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .frame(width: 200)
                }
            )
    }
}

extension View {
    func visionOSStyle() -> some View {
        self.modifier(VisionOSModifier())
    }
}

struct EventRowVisionOS: View {
    let event: ICSEvent
    let onDelete: () -> Void
    let onExport: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        EventRow(event: event, onDelete: onDelete, onExport: onExport, onEdit: onEdit)
            .hoverEffect()
            .contextMenu(menuItems: {
                Button {
                    onEdit()
                } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                
                Button {
                    onExport()
                } label: {
                    Label("Teilen", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            })
    }
}
#endif

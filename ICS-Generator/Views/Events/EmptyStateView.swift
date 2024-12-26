import SwiftUI

struct EmptyStateView: View {
    @Binding var showAddEvent: Bool
    @Binding var showingImportSheet: Bool
    @Binding var showingValidationSheet: Bool
    @State private var isAnimating = false
    @State private var showingInfo = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated Header
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 70))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .symbolEffect(.bounce.down, options: .speed(0.5), value: isAnimating)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                
                VStack(spacing: 8) {
                    Text("Keine Termine")
                        .font(.title2)
                        .bold()
                    
                    Text("Erstellen Sie Ihren ersten Termin oder importieren Sie bestehende")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 10)
            
            // Action Buttons
            VStack(spacing: 16) {
                // Create Button
                Button(action: { showAddEvent = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Termin erstellen")
                                .font(.headline)
                            Text("Neuen Termin hinzufügen")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                HStack(spacing: 16) {
                    // Import Button
                    Button(action: { showingImportSheet = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                                .foregroundStyle(.green)
                            Text("ICS importieren")
                                .font(.callout)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Validate Button
                    Button(action: { showingValidationSheet = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.shield")
                                .font(.title2)
                                .foregroundStyle(.purple)
                            Text("ICS validieren")
                                .font(.callout)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
            
            // Info Section
            VStack(spacing: 16) {
                Button(action: { withAnimation { showingInfo.toggle() }}) {
                    HStack {
                        Text("Was ist eine ICS-Datei?")
                            .font(.subheadline)
                            .bold()
                        
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(showingInfo ? 90 : 0))
                    }
                    .foregroundColor(.secondary)
                }
                
                if showingInfo {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ICS ist ein universelles Format für Kalenderdaten, das von allen gängigen Kalender-Apps unterstützt wird.")
                            .font(.subheadline)
                        
                        Text("Perfekt geeignet für:")
                            .font(.subheadline)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach([
                                "Digitalisierung auf Papier gedruckter Termine aus Kindergarten und Schule",
                                "Teilen von Veranstaltungskalendern",
                                "Export von Terminen aus anderen Systemen",
                                "Backup wichtiger Termine"
                            ], id: \.self) { use in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .padding(.top, 7)
                                    
                                    Text(use)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.leading, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal)
            .opacity(isAnimating ? 1 : 0)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        EmptyStateView(
            showAddEvent: .constant(false),
            showingImportSheet: .constant(false),
            showingValidationSheet: .constant(false)
        )
    }
}

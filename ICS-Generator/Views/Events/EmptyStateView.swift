import SwiftUI

struct EmptyStateView: View {
    @Binding var showAddEvent: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 64))
                    .foregroundColor(CustomColors.accent)
                
                VStack(spacing: 8) {
                    Text("Willkommen beim ICS Generator!")
                        .font(.title2)
                        .bold()
                        .foregroundColor(CustomColors.text)
                    
                    Text("Erstellen Sie Ihre ersten Termine und exportieren Sie sie als ICS-Datei.")
                        .font(.subheadline)
                        .foregroundColor(CustomColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            // Feature Cards
            VStack(spacing: 16) {
                FeatureCard(
                    icon: "calendar.badge.plus",
                    title: "Termine erstellen",
                    description: "Erstellen Sie Termine mit allen wichtigen Details wie Ort, Zeit und Erinnerungen.",
                    color: .blue
                )
                
                FeatureCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Wiederholungen",
                    description: "Legen Sie wiederkehrende Termine fest - täglich, wöchentlich, monatlich oder jährlich.",
                    color: .green
                )
                
                FeatureCard(
                    icon: "square.and.arrow.up",
                    title: "ICS Export",
                    description: "Exportieren Sie Ihre Termine im ICS-Format und teilen Sie sie mit anderen Kalendern.",
                    color: .orange
                )
                
                FeatureCard(
                    icon: "checkmark.shield",
                    title: "Validierung",
                    description: "Überprüfen Sie importierte ICS-Dateien auf Standardkonformität.",
                    color: .purple
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Action Button
            Button(action: { showAddEvent = true }) {
                Label("Ersten Termin erstellen", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(CustomColors.accent)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(CustomColors.text)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(CustomColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(CustomColors.secondaryBackground)
        .cornerRadius(12)
    }
}

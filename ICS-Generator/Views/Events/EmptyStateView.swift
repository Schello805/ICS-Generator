import SwiftUI

struct EmptyStateView: View {
    @Binding var showAddEvent: Bool
    @Binding var showingImportSheet: Bool
    @Binding var showingValidationSheet: Bool
    @Binding var showingExportOptions: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(CustomColors.accent)
                
                VStack(spacing: 4) {
                    Text("Willkommen beim ICS Generator!")
                        .font(.title3)
                        .bold()
                        .foregroundColor(CustomColors.text)
                    
                    Text("Erstellen Sie Ihre ersten Termine")
                        .font(.subheadline)
                        .foregroundColor(CustomColors.secondaryText)
                }
            }
            
            // Feature Cards in Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                CompactFeatureCard(
                    icon: "calendar.badge.plus",
                    title: "Termine erstellen",
                    color: .blue,
                    action: { showAddEvent = true }
                )
                
                CompactFeatureCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Wiederholungen",
                    color: .green,
                    action: { showAddEvent = true }
                )
                
                CompactFeatureCard(
                    icon: "square.and.arrow.down",
                    title: "ICS Import",
                    color: .orange,
                    action: { showingImportSheet = true }
                )
                
                CompactFeatureCard(
                    icon: "checkmark.shield",
                    title: "ICS Validator",
                    color: .purple,
                    action: { showingValidationSheet = true }
                )
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
}

struct CompactFeatureCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.callout)
                    .foregroundColor(CustomColors.text)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

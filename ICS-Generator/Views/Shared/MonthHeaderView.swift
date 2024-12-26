import SwiftUI

struct MonthHeaderView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background(.ultraThinMaterial)
        }
    }
}

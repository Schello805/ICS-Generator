import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    let systemImage: String
    
    init(systemImage: String = "plus", action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: systemImage)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                        .shadow(radius: 4, y: 2)
                }
                .padding()
                .transition(.scale)
            }
        }
    }
}

struct FloatingActionButton_Previews: PreviewProvider {
    static var previews: some View {
        FloatingActionButton(systemImage: "plus.circle.fill") {}
    }
}

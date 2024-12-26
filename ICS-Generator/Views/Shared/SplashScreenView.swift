import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation = 0.0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor.opacity(0.6),
                        Color.accentColor
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(size)
                        .opacity(opacity)
                    
                    Text("ICS Generator")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                        .scaleEffect(size)
                        .opacity(opacity)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding(.top, 24)
                        .opacity(opacity)
                }
            }
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) {
                    self.size = 1.0
                    self.opacity = 1.0
                }
                
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    self.rotation = 360.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

import SwiftUI

@main
struct ICSGeneratorApp: App {
    @StateObject private var viewModel = EventViewModel()
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    
    init() {
        // Spracheinstellung anwenden
        if let languageCode = UserDefaults.standard.string(forKey: "appLanguage"),
           languageCode != "system" {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(viewModel)
        }
    }
}

import SwiftUI

#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum Platform {
    static func copyToClipboard(_ string: String) {
        #if os(iOS) || os(visionOS)
        UIPasteboard.general.string = string
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
    
    static func share(items: [Any],
                     completion: @escaping (Bool) -> Void) {
        #if os(iOS) || os(visionOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            completion(false)
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        if let presenter = activityViewController.popoverPresentationController {
            presenter.sourceView = window
            presenter.sourceRect = CGRect(x: window.bounds.midX,
                                        y: window.bounds.midY,
                                        width: 0,
                                        height: 0)
        }
        
        rootViewController.present(activityViewController, animated: true) {
            completion(true)
        }
        #elseif os(macOS)
        let picker = NSSavePanel()
        picker.allowedContentTypes = [.ics]
        picker.canCreateDirectories = true
        picker.isExtensionHidden = false
        picker.allowsOtherFileTypes = false
        picker.title = "ICS-Datei speichern"
        
        picker.begin { result in
            if result == .OK, let url = picker.url,
               let data = (items.first as? String)?.data(using: .utf8) {
                try? data.write(to: url)
                completion(true)
            } else {
                completion(false)
            }
        }
        #endif
    }
}

struct PlatformViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS) || os(visionOS)
        content
            .background(Color(uiColor: .systemBackground))
        #elseif os(macOS)
        content
            .background(Color(nsColor: .windowBackgroundColor))
        #endif
    }
}

import SwiftUI
import MultipeerConnectivity

public struct BrowserView: UIViewControllerRepresentable {
    @ObservedObject var session: GameSession

    public init(session: GameSession) {
        self.session = session
    }

    public func makeUIViewController(context: Context) -> MCBrowserViewController {
        guard let browser = session.browser else {
            // This should not happen if joinGame() was called
            return MCBrowserViewController()
        }
        return browser
    }
    
    public func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) {
        // Nothing to update
    }
}

import SwiftUI
import FirebaseCore

@main
struct BudGetUpApp: App {
    @State private var authService: AuthService

    init() {
        FirebaseApp.configure()
        _authService = State(initialValue: AuthService())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        #endif
    }
}

private struct RootView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        if auth.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if auth.isSignedIn, let uid = auth.user?.uid {
            ContentView()
                .environment(AppStore(uid: uid))
        } else {
            SignInView()
        }
    }
}

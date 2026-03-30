import Foundation
import FirebaseAuth

@MainActor
@Observable
final class AuthService {
    var user: User? = nil
    var isLoading = true
    var errorMessage: String? = nil

    @ObservationIgnored private nonisolated(unsafe) var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isLoading = false
            }
        }
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    var isSignedIn: Bool { user != nil }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    func createAccount(email: String, password: String) async {
        errorMessage = nil
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    private func friendlyError(_ error: Error) -> String {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        switch code {
        case .wrongPassword, .invalidCredential:
            return "Contraseña incorrecta."
        case .userNotFound:
            return "No existe una cuenta con ese correo."
        case .emailAlreadyInUse:
            return "Ya existe una cuenta con ese correo."
        case .weakPassword:
            return "La contraseña debe tener al menos 6 caracteres."
        case .invalidEmail:
            return "El correo no es válido."
        default:
            return error.localizedDescription
        }
    }
}

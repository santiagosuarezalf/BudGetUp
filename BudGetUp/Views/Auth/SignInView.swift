import SwiftUI

struct SignInView: View {
    @Environment(AuthService.self) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var isCreating = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo / título
            VStack(spacing: 8) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.accentColor)
                Text("BudGetUp")
                    .font(.largeTitle.bold())
                Text("Tu presupuesto, siempre contigo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)

            // Formulario
            VStack(spacing: 16) {
                TextField("Correo electrónico", text: $email)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    #endif
                    .textFieldStyle(.roundedBorder)

                SecureField("Contraseña", text: $password)
                    .textContentType(isCreating ? .newPassword : .password)
                    .textFieldStyle(.roundedBorder)

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        isLoading = true
                        if isCreating {
                            await auth.createAccount(email: email, password: password)
                        } else {
                            await auth.signIn(email: email, password: password)
                        }
                        isLoading = false
                    }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(isCreating ? "Crear cuenta" : "Iniciar sesión")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Button {
                    isCreating.toggle()
                    auth.errorMessage = nil
                } label: {
                    Text(isCreating
                         ? "¿Ya tienes cuenta? Iniciar sesión"
                         : "¿No tienes cuenta? Crear una")
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 32)
            #if os(macOS)
            .frame(maxWidth: 360)
            #endif

            Spacer()
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 480)
        #endif
    }
}

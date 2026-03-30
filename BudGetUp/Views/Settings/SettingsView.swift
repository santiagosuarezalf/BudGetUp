import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    var body: some View {
        NavigationStack {
            List {
                Section("Visualización") {
                    Picker("Apariencia", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                            Label(mode.label, systemImage: mode.icon).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    NavigationLink(destination: CategoriesView()) {
                        Label("Categorías", systemImage: "tag.fill")
                    }
                    NavigationLink(destination: AccountsView()) {
                        Label("Cuentas", systemImage: "building.columns.fill")
                    }
                    NavigationLink(destination: DebtsView()) {
                        Label("Deudas", systemImage: "creditcard.and.123")
                    }
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}

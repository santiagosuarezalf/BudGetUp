import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
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
            .navigationTitle("Ajustes")
        }
    }
}

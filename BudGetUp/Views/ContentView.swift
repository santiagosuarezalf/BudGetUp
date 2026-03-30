import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List {
                NavigationLink(destination: DashboardView()) {
                    Label("Inicio", systemImage: "house.fill")
                }
                NavigationLink(destination: BudgetTabView()) {
                    Label("Presupuesto", systemImage: "chart.bar.fill")
                }
                NavigationLink(destination: DebtsView()) {
                    Label("Deuda", systemImage: "creditcard.fill")
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
            }
            .navigationTitle("BudGetUp")
            .listStyle(.sidebar)
        } detail: {
            DashboardView()
        }
        #else
        TabView {
            DashboardView()
                .tabItem { Label("Inicio", systemImage: "house.fill") }
            BudgetTabView()
                .tabItem { Label("Presupuesto", systemImage: "chart.bar.fill") }
            NavigationStack { DebtsView() }
                .tabItem { Label("Deuda", systemImage: "creditcard.fill") }
            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
        }
        #endif
    }
}

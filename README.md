# BudGetUp

App de presupuesto personal para macOS e iPhone, construida en SwiftUI. Reemplaza el sistema de seguimiento financiero anterior en Notion.

> **Estado:** En desarrollo activo. Sin icono ni assets finales aún.

---

## ¿Qué hace?

- **Transacciones**: registra ingresos y gastos con categoría, cuenta, fecha y hashtags
- **Presupuesto**: define un límite mensual por categoría y visualiza el avance
- **Deudas**: seguimiento de créditos y tarjetas con cálculo de interés real (E.A. y N.A.M.V.), simulación de saldo efectivo mes a mes y fecha estimada de pago
- **Dashboard**: 4 tipos de gráfica (radar, línea, donut, barras), resumen del mes y vista histórica
- **Sincronización**: los datos se sincronizan en tiempo real entre Mac e iPhone vía Firebase

---

## Plataformas

| Plataforma | Versión mínima |
|---|---|
| macOS | 14 (Sonoma) |
| iOS | 17 |

Un solo codebase con `#if os(macOS)` donde hay diferencias de plataforma.

---

## Stack

- **UI**: SwiftUI (Swift 6)
- **Auth**: Firebase Authentication (email/password)
- **Base de datos**: Cloud Firestore (sync en tiempo real)
- **Gráficas**: Swift Charts + Canvas/Path custom (radar chart)
- **Moneda**: COP — pesos colombianos, sin decimales

---

## Arquitectura

```
App/BudGetUpApp.swift      ← Entry point, configura Firebase y AuthService
Services/AuthService.swift ← @MainActor @Observable, maneja sesión
Services/AppStore.swift    ← Estado central: transacciones, categorías, cuentas, deudas
Services/FirestoreService  ← CRUD y listeners de Firestore
Models/                    ← Structs Codable (Transaction, Category, Account, Debt)
Views/                     ← Dashboard, Budget, Debts, Settings, Auth
Helpers/                   ← Formateo COP, animaciones, utilidades
```

**Flujo de datos:**
```
Firestore ──listener──▶ AppStore ──@Environment──▶ Views
Views ──acción──▶ AppStore ──▶ FirestoreService ──▶ Firestore
```

---

## Configuración para desarrollo

1. Clona el repositorio
2. Abre `BudGetUp.xcodeproj` en Xcode
3. Agrega tu propio `GoogleService-Info.plist` en `BudGetUp/` (no incluido en el repo — contiene credenciales privadas de Firebase)
4. Selecciona el destino (Mac o iPhone) y presiona ⌘R

> Sin el `GoogleService-Info.plist` la app no puede conectarse a Firebase y no funcionará.

---

## Pendiente / Roadmap

- [ ] Icono de la app
- [ ] Assets y pantalla de lanzamiento
- [ ] Capturas de pantalla
- [ ] Soporte para múltiples monedas
- [ ] Exportar datos a CSV/PDF
- [ ] Widgets para iOS

---

## Autor

Santiago Suárez — proyecto personal en desarrollo.

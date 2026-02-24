# Project Context: CashFlow (Flutter)

## Overview

Personal finance manager application migrated from a React/Vite implementation to a native Flutter app. Focuses on simplicity, emoji-based categorization, and credit card management.

## Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Persistence**: SQLite (sqflite) with cross-platform FFI support (Web/Desktop)
- **Notifications**: flutter_local_notifications
- **Charts**: fl_chart
- **Utilities**: intl, uuid, csv, share_plus

## Current State

- **Main Features**:
  - Calculator for quick expense/income entry.
  - History with advanced filters (custom date range, search by aliases, type filters) and pagination.
  - Stats with charts and monthly spending projections.
  - Budgeting per category with progress tracking.
  - Credit card management (cut-off/payment dates).
  - Local notifications for payment reminders.
  - Data management (Export/Import JSON, Export CSV).

## Recent Changes

- ✅ **Infrastructure Upgrade**:
  - Migrated from SharedPreferences to **SQLite** for robust data persistence.
  - Implemented `DatabaseService` with automatic data migration from JSON.
  - Added support for Web/Desktop development via `sqflite_common_ffi`.
- ✅ **Phase 1 UI/Logic Updates**:
  - Implemented pagination and custom date range filters in `HistoryScreen`.
  - Added `BudgetsScreen` for monthly expense control.
  - Integrated `NotificationService` for credit card payment reminders.
  - Added spending projections in `StatsScreen`.
- ✅ **Technical Improvements**:
  - Database Indexes, Foreign Keys, stricter linting, initial unit tests.
  - Android: `POST_NOTIFICATIONS` permission, R8 code shrinking.
- ✅ **Category Type Separation**:
  - Categorías separadas en Income/Expense en todo el app.
  - Presupuestos solo para categorías de gasto.
  - Calculadora filtra categorías según tipo seleccionado.
- ✅ **UI Animations & Transitions** (Latest):
  - `StaggeredFadeSlide` + `AnimatedCounter` widgets reutilizables.
  - Transiciones direccionales fade+slide entre tabs.
  - TransactionCards con bordes/fondo coloreados (verde income, rojo expense, naranja crédito).
  - Balance animado con `AnimatedCounter`, bounce en selección de emoji.
  - Progress bars animados en presupuestos.
- ✅ **Daily Backup & Reminder System**:
  - `BackupService` guarda JSON diario como `YYMMDD.json` en storage externo.
  - Auto-backup al abrir la app (si no existe backup del día anterior).
  - Limpieza automática de backups +30 días.
  - Notificación diaria a las 9PM: "Psss! No olvides registrar".
  - Se cancela automáticamente si el usuario registra algo ese día.
  - Tres toggles en Settings: Recordatorios de pago, Backup Diario, Recordatorio Diario.
  - Cards con iconos unificados (📙 crédito, 📗 débito).
  - Two-step payment flow (cash/card → card selection).
  - Calculator amount bar unificado con botones expense/income.

## URLs & Resources

- Repository: [imLeGEnDco55/cashflow](https://github.com/imLeGEnDco55/cashflow)

## Next Steps

- More micro-interactions and haptic feedback.
- Recurring transactions automation.

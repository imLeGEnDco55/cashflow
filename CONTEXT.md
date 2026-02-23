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
- ✅ **Technical Improvements** (New):
  - **Database Optimized**: Added Indexes (`date`, `category`) and Foreign Keys for better performance and data integrity.
  - **Code Quality**: Enforced stricter linting rules (`analysis_options.yaml`).
  - **Testing**: Added initial unit tests for `Transaction` model.
  - **Config**: Updated `.gitignore` to exclude `.agent/`.
  - **Android**: Added `POST_NOTIFICATIONS` permission and enabled R8 code shrinking for release builds.

## URLs & Resources
- Repository: [imLeGEnDco55/cashflow](https://github.com/imLeGEnDco55/cashflow)

## Next Steps
- Add cloud backup functionality.
- Implement multi-currency support.
- Refine UI animations and transitions.

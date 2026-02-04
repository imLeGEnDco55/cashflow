# 🤝 Handoff: CashFlow (Flutter + SQLite)

## 📌 Estado Actual del Proyecto
Hemos completado la **Fase 1 de Infraestructura**. La aplicación ha pasado de un almacenamiento simple en JSON (`SharedPreferences`) a una base de datos relacional robusta (**SQLite**).

### Logros Recientes:
- **SQLite Core**: Implementación de `DatabaseService` con soporte para Categorías, Tarjetas, Transacciones, Presupuestos y Ajustes.
- **Migración Automática**: Lógica en `FinanceProvider` que mueve los datos del antiguo JSON a la DB en el primer inicio.
- **Soporte Multiplataforma**: Configuración de `sqflite_common_ffi` para permitir desarrollo y testing en **Windows** y **Web (Chrome)** sin colapsar el soporte nativo de Android.
- **Documentación**: README y CONTEXT actualizados con la nueva arquitectura.

## 🛠️ Stack Tecnológico
- **Flutter** (Stable)
- **Sqflite** + **FFI** (Persistencia)
- **Provider** (Estado)
- **Flutter Local Notifications** (Recordatorios)
- **FL Chart** (Estadísticas)

## 📋 Tareas Pendientes (Próximos Pasos)

### 1. Funcionalidad de Backup & Nube
- [ ] Implementar exportación del archivo `.db` directamente.
- [ ] Sincronización opcional con Google Drive / Dropbox.

### 2. Pulido de UI/UX
- [ ] **Animaciones**: Añadir transiciones más fluidas entre pestañas usando `PageController` o `Hero`.
- [ ] **Modo Oscuro**: Revisar el contraste de algunos emojis en fondos muy oscuros.
- [ ] **Gráficos**: Añadir herramientas de "tooltip" más detalladas en los gráficos de `fl_chart`.

### 3. Nuevas Funcionalidades
- [ ] **Multidivisa**: Permitir definir una moneda base y convertir gastos automáticos (API de cambio).
- [ ] **Exportación PDF**: Generar reportes mensuales visuales.

## ⚠️ Notas Técnicas para la Siguiente AI:
- La clase `Transaction` de nuestro modelo entra en conflicto con la de `sqflite`. Siempre importa `sqflite` usando `hide Transaction`.
- El `DatabaseService` inicializa el motor según la plataforma (`kIsWeb` o `defaultTargetPlatform`). No cambies esta lógica sin probar en Chrome y un emulador Android.

---
*Hecho por Antigravity - AI Partner.*

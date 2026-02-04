# 💰 CashFlow - Gestor de Finanzas Emoji-First

¡Bienvenido a **CashFlow**! Una aplicación de finanzas personales diseñada para ser rápida, visual y extremadamente útil. Olvídate de formularios aburridos; aquí tus gastos cobran vida a través de emojis y una lógica inteligente de gestión de crédito.

---

## ✨ Características Principales

### 📱 Registro Ultrarrápido (Emoji-First)
*   **Calculadora Integrada:** Ingresa montos y realiza cálculos rápidos sin salir de la app.
*   **Categorización por Emojis:** Identifica tus gastos de un vistazo (🍔 Comida, 🚗 Transporte, 🛍️ Compras).
*   **Super-Emojis (Desglose):** ¿Un ticket de supermercado con varias cosas? Desglosa un solo gasto en múltiples categorías para un control total.
*   **Transacciones Fijas:** Marca gastos o ingresos como recurrentes para identificarlos fácilmente.

### 💳 Gestión Inteligente de Crédito
*   **Tarjetas Dinámicas:** Configura tarjetas de Débito y Crédito con colores y emojis personalizados.
*   **Control de Ciclos:** Define días de **Corte** y **Pago**. La app te mostrará una cuenta regresiva para tus próximas obligaciones.
*   **Notificaciones de Pago:** No vuelvas a pagar intereses. Recibe recordatorios locales antes de tu fecha de pago.
*   **Seguimiento de Deuda:** Visualiza exactamente cuánto debes en cada tarjeta y realiza "Pagos a Tarjeta" para sanear tus finanzas.

### 📊 Análisis y Control
*   **Presupuestos Mensuales:** Establece límites por categoría y sigue tu progreso con barras visuales de "calor".
*   **Estadísticas Detalladas:** Gráficos acumulados y por categoría para entender a dónde se va tu dinero.
*   **Historial Avanzado:** Filtra por fecha, tipo de transacción, categoría o palabra clave. Paginación integrada para manejar miles de registros sin lag.

### 💾 Datos y Seguridad
*   **Persistencia SQLite:** Tus datos se guardan en una base de datos local profesional, rápida y segura.
*   **Importación/Exportación:** Respalda tu información en **JSON** o exporta tu historial a **CSV** para analizarlo en Excel/Sheets.
*   **Privacidad Total:** Tus datos nunca salen de tu dispositivo. Sin cuentas, sin nube obligatoria, sin rastreo.

---

## 🛠️ Arquitectura Técnica

La app está construida con un stack moderno para garantizar rendimiento en dispositivos Android:

*   **[Flutter](https://flutter.dev/)** - Framework principal para una UI fluida a 60fps.
*   **[Sqflite](https://pub.dev/packages/sqflite)** - Motor de base de datos relacional para persistencia robusta.
*   **[Provider](https://pub.dev/packages/provider)** - Gestión de estado escalable y eficiente.
*   **[Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)** - Sistema de alertas para pagos.
*   **[FL Chart](https://pub.dev/packages/fl_chart)** - Visualizaciones de datos potentes y animadas.

---

## 🚀 Instalación y Desarrollo

### Requisitos
- Flutter SDK (Canal Stable)
- Android Studio / VS Code
- Un dispositivo Android o emulador (recomendado)

### Pasos
1.  **Clona el repositorio:**
    ```bash
    git clone https://github.com/imLeGEnDco55/cashflow.git
    ```
2.  **Instala dependencias:**
    ```bash
    flutter pub get
    ```
3.  **Ejecuta la aplicación:**
    ```bash
    flutter run
    ```
    *Nota: Aunque está optimizada para Android, el proyecto cuenta con soporte experimental para Web (Chrome) y Windows Desktop para facilitar el desarrollo.*

---

## 🤝 Contribuciones y Feedback
Este es un proyecto **MVP (Most Valuable Project)** en constante evolución. Si tienes una idea para una nueva funcionalidad o has encontrado un bug, ¡abre un issue o un pull request!

---

<p align="center">
  Hecho con 💡 para que dominar tu dinero sea tan fácil como enviar un emoji.
</p>

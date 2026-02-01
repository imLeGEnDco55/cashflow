# CONTEXT

## 📌 Proyecto: CashFlow (Gestor de Finanzas Personales)

**Estado Actual:**
- Rama: `main` (up to date)
- Último Merge: PR #14 (Delete Confirmation & Accessibility)
- **Fix Reciente:** Se corrigió error 404 en GitHub Pages. El problema era que el build no se había deployado correctamente. Se instaló `gh-pages`, se agregó script `deploy` en `package.json`, y se ejecutó `npm run deploy` exitosamente.
- Build Status: ✅ `npm run build` exitoso.
- Deploy Status: ✅ Publicado en rama `gh-pages`

## 🛠 Tech Stack
- **Frontend:** React + TypeScript + Vite
- **Estilos:** Tailwind CSS + shadcn/ui
- **Iconos:** Lucide React
- **Gráficos:** Recharts
- **Gestor de Paquetes:** npm/bun (bun.lockb presente, pero se usó npm para el fix)
- **Deploy:** gh-pages (rama `gh-pages`)

## 📂 Estructura Clave
- `src/`: Código fuente
- `dist/`: Build de producción (deployado a GitHub Pages)
- `d:\Appz\cashflow`: Root

## 📝 Notas de Desarrollo
- El usuario prefiere abstracción técnica ("QUÉ" vs "CÓMO").
- MVP constante.
- Hardware limitado (i5-2500k).
- **Regla de Oro:** Mantener este archivo actualizado.

## 🚀 Next Steps
1. Verificar que GitHub Pages esté configurado en Settings → Pages → Branch: `gh-pages` / (root)
2. Probar la app en: `https://imlegendco55.github.io/cashflow/`
3. Continuar con nuevas features o mejoras visuales según feedback del usuario.

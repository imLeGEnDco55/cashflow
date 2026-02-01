# CONTEXT

## 📌 Proyecto: CashFlow (Gestor de Finanzas Personales)

**Estado Actual:**
- Rama: `main`
- Build Status: ✅ `npm run build` exitoso
- Deploy Status: ✅ Publicado en rama `gh-pages`
- **Última Refactorización:** Limpieza masiva de código sin usar

## 🛠 Tech Stack
- **Frontend:** React 18 + TypeScript + Vite
- **Estilos:** Tailwind CSS + shadcn/ui (11 componentes)
- **Iconos:** Lucide React
- **Gráficos:** Recharts
- **Gestor de Paquetes:** npm (solo `package-lock.json`)
- **Deploy:** gh-pages

## 📂 Estructura Clave
- `src/components/ui/` - 11 componentes shadcn usados
- `src/components/` - 4 screens principales
- `src/hooks/` - useFinanceData + use-toast
- `src/contexts/` - FinanceContext

## 📝 Notas de Desarrollo
- El usuario prefiere abstracción técnica ("QUÉ" vs "CÓMO")
- MVP constante
- Hardware limitado (i5-2500k)
- **Regla de Oro:** Mantener este archivo actualizado

## 🧹 Última Limpieza (Feb 2026)
- Eliminados 38 componentes UI sin usar
- Eliminadas 31 dependencias npm
- Removidas carpetas `.Jules/` y `.lovable/`
- Unificados lockfiles (solo npm)
- Tests: 2 tests preexistentes fallan (debounce timing)

## 🚀 Next Steps
1. Verificar app en: `https://imlegendco55.github.io/cashflow/`
2. Ejecutar `npm run deploy` para publicar cambios
3. Considerar fix de los 2 tests que fallan (opcional)

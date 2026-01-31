## 2024-05-22 - Calculator Accessibility & Feedback
**Learning:** The app relied on `title` attributes for icon-only buttons (categories), which is often insufficient for screen readers and touch devices. Also, critical actions like adding a transaction lacked explicit feedback.
**Action:** When using icon-only buttons, always ensure `aria-label` is present and matches the intent. Always provide feedback (toast/alert) for form submissions.

## 2025-01-31 - Destructive Action Confirmation
**Learning:** Destructive actions (like delete) should always have a confirmation dialog to prevent accidental data loss. This also provides a better accessible experience than a silent, instant delete.
**Action:** Use `AlertDialog` for all destructive actions. Ensure the trigger button has an `aria-label` describing the specific action (e.g., "Delete transaction").

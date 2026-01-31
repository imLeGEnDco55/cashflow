## 2024-05-22 - Calculator Accessibility & Feedback
**Learning:** The app relied on `title` attributes for icon-only buttons (categories), which is often insufficient for screen readers and touch devices. Also, critical actions like adding a transaction lacked explicit feedback.
**Action:** When using icon-only buttons, always ensure `aria-label` is present and matches the intent. Always provide feedback (toast/alert) for form submissions.

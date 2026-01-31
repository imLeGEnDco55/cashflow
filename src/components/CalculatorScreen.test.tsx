import { render, screen, fireEvent } from '@testing-library/react';
import { CalculatorScreen } from './CalculatorScreen';
import { FinanceProvider } from '@/contexts/FinanceContext';
import { toast } from 'sonner';
import { vi, describe, it, expect } from 'vitest';

// Mock sonner
vi.mock('sonner', () => ({
  toast: {
    success: vi.fn(),
  },
}));

describe('CalculatorScreen UX', () => {
  it('should provide accessible labels and visual feedback', () => {
    render(
      <FinanceProvider>
        <CalculatorScreen />
      </FinanceProvider>
    );

    // 1. Accessibility Check: Input should have a label "Monto"
    // This is expected to fail initially as there is no aria-label or label
    const amountInput = screen.getByLabelText('Monto');
    expect(amountInput).toBeInTheDocument();

    // 2. Accessibility Check: Category buttons should use aria-label
    // While title works, we want to ensure explicit aria-label for better a11y support
    // We'll check if we can get it by role and name
    const categoryBtn = screen.getByRole('button', { name: 'Comida' });
    expect(categoryBtn).toHaveAttribute('aria-label', 'Comida');

    // 3. Feedback Check: Toast should appear on submit
    fireEvent.change(amountInput, { target: { value: '100' } });
    fireEvent.click(categoryBtn);

    const cashBtn = screen.getByText(/Cash/i);
    fireEvent.click(cashBtn);

    expect(toast.success).toHaveBeenCalledWith('Transacción agregada');
  });
});

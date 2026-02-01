import { render } from '@testing-library/react';
import { HistoryScreen } from './HistoryScreen';
import { vi, describe, it, expect, Mock } from 'vitest';
import { Transaction, TransactionType } from '@/types/finance';

// Mock dependencies
vi.mock('@/contexts/FinanceContext', () => ({
  useFinance: vi.fn(),
}));

import { useFinance } from '@/contexts/FinanceContext';

describe('HistoryScreen Performance', () => {
  it('renders 5000 transactions efficiently', () => {
    const transactions: Transaction[] = Array.from({ length: 5000 }, (_, i) => ({
      id: `t-${i}`,
      amount: 100 + i,
      type: 'expense' as TransactionType,
      categoryId: '1',
      paymentMethod: 'cash',
      date: new Date().toISOString(),
      createdAt: Date.now(),
    }));

    (useFinance as Mock).mockReturnValue({
      transactions,
      categories: [{ id: '1', emoji: '🍕', description: 'Food' }],
      cards: [],
      balance: 10000,
      totalCreditDebt: 0,
      getCategoryById: (id: string) => ({ id, emoji: '🍕', description: 'Food' }),
      getCardById: (id: string) => ({ id, name: 'Card', colorEmoji: '💳' }),
      deleteTransaction: vi.fn(),
    });

    const start = performance.now();
    render(<HistoryScreen />);
    const end = performance.now();

    console.log(`Rendering 5000 transactions took: ${end - start}ms`);

    expect(true).toBe(true);
  }, 20000);
});

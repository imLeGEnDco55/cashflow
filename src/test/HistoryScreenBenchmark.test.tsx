
import { render } from '@testing-library/react';
import { HistoryScreen } from '@/components/HistoryScreen';
import { vi, describe, it } from 'vitest';
import { Transaction, Category, Card } from '@/types/finance';

// Mock data
const mockTransactions: Transaction[] = Array.from({ length: 5000 }, (_, i) => ({
  id: `t-${i}`,
  amount: 100 + i,
  type: 'expense',
  categoryId: '1',
  paymentMethod: 'cash',
  date: new Date().toISOString(),
  createdAt: Date.now(),
}));

const mockCategories: Category[] = [
  { id: '1', emoji: '🍔', description: 'Food' },
];

const mockCards: Card[] = [];

// Mock useFinance
vi.mock('@/contexts/FinanceContext', () => ({
  useFinance: () => ({
    transactions: mockTransactions,
    categories: mockCategories,
    cards: mockCards,
    balance: 1000,
    totalCreditDebt: 0,
    getCategoryById: (id: string) => mockCategories.find(c => c.id === id),
    getCardById: (id: string) => mockCards.find(c => c.id === id),
    deleteTransaction: vi.fn(),
  }),
}));

// Mock scrollIntoView which might be used or other DOM methods
window.HTMLElement.prototype.scrollIntoView = vi.fn();

describe('HistoryScreen Performance', () => {
  it('renders 5000 transactions efficiently', () => {
    const start = performance.now();

    render(<HistoryScreen />);

    const end = performance.now();
    const duration = end - start;

    console.log(`Render time for 5000 items: ${duration.toFixed(2)}ms`);

    // We don't assert a specific time because it depends on the machine,
    // but we log it to see the improvement.
  }, 20000); // Increased timeout
});

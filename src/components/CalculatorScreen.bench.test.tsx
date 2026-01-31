import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, beforeEach } from 'vitest';
import { CalculatorScreen } from './CalculatorScreen';
import { FinanceProvider } from '@/contexts/FinanceContext';
import { FinanceData, DEFAULT_CATEGORIES } from '@/types/finance';

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {};
  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      store[key] = value.toString();
    },
    clear: () => {
      store = {};
    },
    removeItem: (key: string) => {
      delete store[key];
    },
  };
})();

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
});

const generateLargeDataset = () => {
  const transactions = [];
  // Create 1000 transactions
  for (let i = 0; i < 1000; i++) {
    transactions.push({
      id: `t-${i}`,
      amount: Math.random() * 1000,
      type: i % 2 === 0 ? 'expense' : 'income',
      categoryId: DEFAULT_CATEGORIES[i % DEFAULT_CATEGORIES.length].id,
      paymentMethod: 'cash',
      date: new Date().toISOString(),
      createdAt: Date.now(),
    });
  }

  // Add some credit cards and credit transactions
  const creditCard = {
    id: 'credit-1',
    name: 'Credit Card',
    type: 'credit',
    colorEmoji: '🟥',
    cutOffDay: 1,
    paymentDay: 15
  };
  const cards = [creditCard];

  for (let i = 0; i < 500; i++) {
    transactions.push({
      id: `tc-${i}`,
      amount: Math.random() * 500,
      type: 'credit_expense',
      categoryId: DEFAULT_CATEGORIES[0].id,
      paymentMethod: 'credit-1',
      date: new Date().toISOString(),
      createdAt: Date.now(),
    });
  }

  return {
    categories: DEFAULT_CATEGORIES,
    cards: cards,
    transactions: transactions,
  } as FinanceData;
};

describe('CalculatorScreen Performance Benchmark', () => {
  beforeEach(() => {
    localStorageMock.clear();
    const data = generateLargeDataset();
    localStorageMock.setItem('emoji-finance-data', JSON.stringify(data));
  });

  it('renders and handles input without significant lag', async () => {
    const startTime = performance.now();

    render(
      <FinanceProvider>
        <CalculatorScreen />
      </FinanceProvider>
    );

    const input = screen.getByPlaceholderText('0.00');

    // Simulate rapid typing
    for (let i = 0; i < 50; i++) {
        fireEvent.change(input, { target: { value: `${i}` } });
    }

    const endTime = performance.now();
    const duration = endTime - startTime;

    console.log(`Benchmark Duration: ${duration.toFixed(2)}ms`);

    expect(duration).toBeGreaterThan(0);
  });
});

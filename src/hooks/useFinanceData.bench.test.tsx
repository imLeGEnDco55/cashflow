import { renderHook, act } from '@testing-library/react';
import { useFinanceData } from './useFinanceData';
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { Transaction, Category, Card } from '@/types/finance';

// Increase size to make it noticeable
const largeDataSize = 5000;
const updatesCount = 50;

// Mock types since I don't want to import them if they are complex or I can just assume shape
// But I imported them above.

describe('useFinanceData Performance Benchmark', () => {
  beforeEach(() => {
    // Setup large initial data in localStorage
    const largeTransactions: Transaction[] = Array.from({ length: largeDataSize }, (_, i) => ({
      id: `t-${i}`,
      amount: 100,
      type: 'expense',
      categoryId: 'food',
      date: '2023-01-01',
      paymentMethod: 'cash',
      createdAt: Date.now(),
    }));

    const initialData = {
      categories: [] as Category[],
      cards: [] as Card[],
      transactions: largeTransactions,
    };

    localStorage.setItem('emoji-finance-data', JSON.stringify(initialData));
  });

  afterEach(() => {
    localStorage.clear();
  });

  it('measures time to add multiple transactions', () => {
    const { result } = renderHook(() => useFinanceData());

    const startTime = performance.now();

    for (let i = 0; i < updatesCount; i++) {
        act(() => {
            result.current.addTransaction({
                amount: 50,
                type: 'income',
                categoryId: 'salary',
                date: '2023-01-02',
                paymentMethod: 'cash',
            });
        });
    }

    const endTime = performance.now();
    const duration = endTime - startTime;

    console.log(`[Benchmark] Time taken for ${updatesCount} updates with ${largeDataSize} initial items: ${duration.toFixed(2)}ms`);

    expect(result.current.transactions.length).toBe(largeDataSize + updatesCount);
  });
});

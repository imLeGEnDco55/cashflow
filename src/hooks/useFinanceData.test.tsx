import { renderHook, act } from '@testing-library/react';
import { useFinanceData } from './useFinanceData';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

describe('useFinanceData', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('saves data to localStorage on unmount', () => {
    const { result, unmount } = renderHook(() => useFinanceData());

    act(() => {
      result.current.addTransaction({
        amount: 100,
        type: 'expense',
        category: 'test',
        date: '2023-01-01',
        description: 'Unmount Test',
        paymentMethod: 'cash',
      });
    });

    // Verify data is NOT saved immediately (due to debounce)
    const storedBefore = localStorage.getItem('emoji-finance-data');
    if (storedBefore) {
        expect(storedBefore).not.toContain('Unmount Test');
    }

    // Unmount the hook
    unmount();

    // Verify data IS saved after unmount
    const storedAfter = localStorage.getItem('emoji-finance-data');
    expect(storedAfter).toContain('Unmount Test');
  });

  it('debounces save operations', () => {
    const { result } = renderHook(() => useFinanceData());

    act(() => {
      result.current.addTransaction({
        amount: 50,
        type: 'income',
        category: 'salary',
        date: '2023-01-02',
        description: 'Debounce Test',
        paymentMethod: 'cash',
      });
    });

    expect(localStorage.getItem('emoji-finance-data') || '').not.toContain('Debounce Test');

    // Fast forward time
    act(() => {
      vi.advanceTimersByTime(1000);
    });

    expect(localStorage.getItem('emoji-finance-data')).toContain('Debounce Test');
  });
});

import { useState, useEffect, useCallback, useMemo } from 'react';
import { FinanceData, Transaction, Category, Card, DEFAULT_CATEGORIES, DEFAULT_CARDS } from '@/types/finance';

const STORAGE_KEY = 'emoji-finance-data';

const getInitialData = (): FinanceData => {
  if (typeof window === 'undefined') {
    return { categories: DEFAULT_CATEGORIES, cards: DEFAULT_CARDS, transactions: [] };
  }
  
  const stored = localStorage.getItem(STORAGE_KEY);
  if (stored) {
    try {
      return JSON.parse(stored);
    } catch {
      return { categories: DEFAULT_CATEGORIES, cards: DEFAULT_CARDS, transactions: [] };
    }
  }
  return { categories: DEFAULT_CATEGORIES, cards: DEFAULT_CARDS, transactions: [] };
};

export function useFinanceData() {
  const [data, setData] = useState<FinanceData>(getInitialData);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  }, [data]);

  const addTransaction = useCallback((transaction: Omit<Transaction, 'id' | 'createdAt'>) => {
    const newTransaction: Transaction = {
      ...transaction,
      id: crypto.randomUUID(),
      createdAt: Date.now(),
    };
    setData(prev => ({
      ...prev,
      transactions: [newTransaction, ...prev.transactions],
    }));
  }, []);

  const deleteTransaction = useCallback((id: string) => {
    setData(prev => ({
      ...prev,
      transactions: prev.transactions.filter(t => t.id !== id),
    }));
  }, []);

  const addCategory = useCallback((category: Omit<Category, 'id'>) => {
    const newCategory: Category = {
      ...category,
      id: crypto.randomUUID(),
    };
    setData(prev => ({
      ...prev,
      categories: [...prev.categories, newCategory],
    }));
  }, []);

  const updateCategory = useCallback((id: string, updates: Partial<Omit<Category, 'id'>>) => {
    setData(prev => ({
      ...prev,
      categories: prev.categories.map(c => c.id === id ? { ...c, ...updates } : c),
    }));
  }, []);

  const deleteCategory = useCallback((id: string) => {
    setData(prev => ({
      ...prev,
      categories: prev.categories.filter(c => c.id !== id),
    }));
  }, []);

  const addCard = useCallback((card: Omit<Card, 'id'>) => {
    const newCard: Card = {
      ...card,
      id: crypto.randomUUID(),
    };
    setData(prev => ({
      ...prev,
      cards: [...prev.cards, newCard],
    }));
  }, []);

  const updateCard = useCallback((id: string, updates: Partial<Omit<Card, 'id'>>) => {
    setData(prev => ({
      ...prev,
      cards: prev.cards.map(c => c.id === id ? { ...c, ...updates } : c),
    }));
  }, []);

  const deleteCard = useCallback((id: string) => {
    setData(prev => ({
      ...prev,
      cards: prev.cards.filter(c => c.id !== id),
    }));
  }, []);

  // Balance calculation:
  // + income
  // - expense (cash/debit)
  // - credit_payment (when you pay off credit card, money leaves your account)
  // credit_expense does NOT affect balance (it's debt, not real money movement)
  const balance = useMemo(() => {
    return data.transactions.reduce((acc, t) => {
      switch (t.type) {
        case 'income':
          return acc + t.amount;
        case 'expense':
        case 'credit_payment':
          return acc - t.amount;
        case 'credit_expense':
          return acc; // No balance change for credit purchases
        default:
          return acc;
      }
    }, 0);
  }, [data.transactions]);

  // Pre-calculate debt for all cards in one pass
  const cardDebts = useMemo(() => {
    const debts: Record<string, number> = {};
    for (const t of data.transactions) {
      if (t.type === 'credit_expense') {
        debts[t.paymentMethod] = (debts[t.paymentMethod] || 0) + t.amount;
      } else if (t.type === 'credit_payment' && t.targetCardId) {
        debts[t.targetCardId] = (debts[t.targetCardId] || 0) - t.amount;
      }
    }
    return debts;
  }, [data.transactions]);

  // Get debt for a specific credit card
  const getCardDebt = useCallback((cardId: string) => {
    return cardDebts[cardId] || 0;
  }, [cardDebts]);

  // Get total credit debt across all cards
  const totalCreditDebt = useMemo(() => {
    const creditCards = data.cards.filter(c => c.type === 'credit');
    return creditCards.reduce((total, card) => total + Math.max(0, cardDebts[card.id] || 0), 0);
  }, [data.cards, cardDebts]);

  // Get all credit cards with their current debt
  const creditCardsWithDebt = useMemo(() => {
    return data.cards
      .filter(c => c.type === 'credit')
      .map(card => ({
        ...card,
        debt: Math.max(0, getCardDebt(card.id)),
      }));
  }, [data.cards, getCardDebt]);

  const getCategoryById = useCallback((id: string) => {
    return data.categories.find(c => c.id === id);
  }, [data.categories]);

  const getCardById = useCallback((id: string) => {
    return data.cards.find(c => c.id === id);
  }, [data.cards]);

  const exportData = useCallback(() => {
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `emoji-finance-backup-${new Date().toISOString().split('T')[0]}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }, [data]);

  const importData = useCallback((file: File) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const imported = JSON.parse(e.target?.result as string) as FinanceData;
        if (imported.categories && imported.cards && imported.transactions) {
          setData(imported);
        }
      } catch {
        console.error('Error importing data');
      }
    };
    reader.readAsText(file);
  }, []);

  return {
    ...data,
    addTransaction,
    deleteTransaction,
    addCategory,
    updateCategory,
    deleteCategory,
    addCard,
    updateCard,
    deleteCard,
    balance,
    getCardDebt,
    totalCreditDebt,
    creditCardsWithDebt,
    getCategoryById,
    getCardById,
    exportData,
    importData,
  };
}

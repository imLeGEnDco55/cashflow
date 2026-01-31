import { createContext, useContext, ReactNode, useMemo } from 'react';
import { useFinanceData } from '@/hooks/useFinanceData';

type FinanceContextType = ReturnType<typeof useFinanceData>;

const FinanceContext = createContext<FinanceContextType | null>(null);

export function FinanceProvider({ children }: { children: ReactNode }) {
  const financeData = useFinanceData();

  const value = useMemo(() => financeData, [
    financeData.transactions,
    financeData.categories,
    financeData.cards,
    financeData.addTransaction,
    financeData.deleteTransaction,
    financeData.addCategory,
    financeData.updateCategory,
    financeData.deleteCategory,
    financeData.addCard,
    financeData.updateCard,
    financeData.deleteCard,
    financeData.balance,
    financeData.getCardDebt,
    financeData.totalCreditDebt,
    financeData.creditCardsWithDebt,
    financeData.getCategoryById,
    financeData.getCardById,
    financeData.exportData,
    financeData.importData,
  ]);
  
  return (
    <FinanceContext.Provider value={value}>
      {children}
    </FinanceContext.Provider>
  );
}

export function useFinance() {
  const context = useContext(FinanceContext);
  if (!context) {
    throw new Error('useFinance must be used within a FinanceProvider');
  }
  return context;
}

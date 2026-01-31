export interface Category {
  id: string;
  emoji: string;
  description: string;
}

export interface Card {
  id: string;
  name: string;
  type: 'credit' | 'debit';
  colorEmoji: string;
}

export const CARD_COLORS = ['🟥', '🟧', '🟨', '🟩', '🟦', '🟪', '🟫', '⬛', '⬜'] as const;

// Transaction types:
// - 'income': Money coming in (+balance)
// - 'expense': Money going out via cash/debit (-balance)
// - 'credit_expense': Purchase with credit card (NO balance change, +card debt)
// - 'credit_payment': Paying off credit card (-balance, -card debt)
export type TransactionType = 'income' | 'expense' | 'credit_expense' | 'credit_payment';

export interface Transaction {
  id: string;
  amount: number;
  type: TransactionType;
  categoryId: string;
  paymentMethod: 'cash' | string; // 'cash' or card id
  date: string; // ISO string
  createdAt: number; // timestamp
  // For credit_payment, this references which card is being paid
  targetCardId?: string;
}

export interface FinanceData {
  categories: Category[];
  cards: Card[];
  transactions: Transaction[];
}

export const DEFAULT_CATEGORIES: Category[] = [
  { id: '1', emoji: '🍕', description: 'Comida' },
  { id: '2', emoji: '🏠', description: 'Casa' },
  { id: '3', emoji: '💼', description: 'Trabajo' },
  { id: '4', emoji: '🎮', description: 'Entretenimiento' },
  { id: '5', emoji: '🚗', description: 'Transporte' },
  { id: '6', emoji: '💊', description: 'Salud' },
  { id: '7', emoji: '🛒', description: 'Compras' },
  { id: '8', emoji: '💰', description: 'Salario' },
  { id: 'credit-payment', emoji: '💳', description: 'Pago de tarjeta' },
];

export const DEFAULT_CARDS: Card[] = [];

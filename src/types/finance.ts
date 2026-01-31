export interface Category {
  id: string;
  emoji: string;
  description: string;
}

export interface Card {
  id: string;
  name: string;
  type: 'credit' | 'debit';
}

export interface Transaction {
  id: string;
  amount: number;
  type: 'income' | 'expense';
  categoryId: string;
  paymentMethod: 'cash' | string; // 'cash' or card id
  date: string; // ISO string
  createdAt: number; // timestamp
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
];

export const DEFAULT_CARDS: Card[] = [];

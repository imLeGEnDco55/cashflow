import { useState } from 'react';
import { Plus, Minus, Banknote, CreditCard } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { useFinance } from '@/contexts/FinanceContext';
import { cn } from '@/lib/utils';
import { TransactionType } from '@/types/finance';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

export function CalculatorScreen() {
  const { 
    categories, 
    cards, 
    addTransaction, 
    balance,
    totalCreditDebt: totalDebt,
    creditCardsWithDebt,
    getCardById,
  } = useFinance();
  
  const [amount, setAmount] = useState('');
  const [type, setType] = useState<'income' | 'expense'>('expense');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [showCardSelector, setShowCardSelector] = useState(false);
  const [showPayCardSelector, setShowPayCardSelector] = useState(false);

  // Filter out the credit payment category from normal selection (it's used automatically)
  const displayCategories = categories.filter(c => c.id !== 'credit-payment');

  const handleAmountChange = (value: string) => {
    const sanitized = value.replace(/[^0-9.]/g, '');
    const parts = sanitized.split('.');
    if (parts.length > 2) return;
    if (parts[1]?.length > 2) return;
    setAmount(sanitized);
  };

  const handleSubmit = (paymentMethod: 'cash' | string) => {
    if (!amount || !selectedCategory || parseFloat(amount) <= 0) return;

    const card = paymentMethod !== 'cash' ? getCardById(paymentMethod) : null;
    
    // Determine transaction type based on payment method
    let transactionType: TransactionType;
    if (type === 'income') {
      transactionType = 'income';
    } else if (card?.type === 'credit') {
      transactionType = 'credit_expense'; // Credit card purchase = debt, not expense
    } else {
      transactionType = 'expense'; // Cash or debit = real expense
    }

    addTransaction({
      amount: parseFloat(amount),
      type: transactionType,
      categoryId: selectedCategory,
      paymentMethod,
      date: new Date().toISOString(),
    });

    // Reset form
    setAmount('');
    setSelectedCategory(null);
    setShowCardSelector(false);
  };

  const handlePayCard = (cardId: string) => {
    if (!amount || parseFloat(amount) <= 0) return;

    addTransaction({
      amount: parseFloat(amount),
      type: 'credit_payment',
      categoryId: 'credit-payment',
      paymentMethod: 'cash', // Payment comes from your real money
      targetCardId: cardId,
      date: new Date().toISOString(),
    });

    setAmount('');
    setShowPayCardSelector(false);
  };

  const canSubmit = amount && selectedCategory && parseFloat(amount) > 0;
  const canPayCard = amount && parseFloat(amount) > 0;

  return (
    <div className="flex flex-col h-full pb-20">
      {/* Balance Header */}
      <div className="text-center py-4">
        <p className="text-sm text-muted-foreground mb-1">Balance Disponible</p>
        <h1 className={cn(
          "text-4xl font-bold transition-colors",
          balance >= 0 ? "text-success" : "text-destructive"
        )}>
          ${balance.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
        </h1>
        
        {/* Credit Debt Display */}
        {totalDebt > 0 && (
          <div className="mt-2 flex items-center justify-center gap-2">
            <span className="text-sm text-muted-foreground">Deuda en tarjetas:</span>
            <span className="text-sm font-semibold text-destructive">
              ${totalDebt.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
            </span>
          </div>
        )}
      </div>

      {/* Amount Input */}
      <Card className="mx-4 p-4 mb-4 shadow-lg">
        <div className="flex items-center gap-3">
          <span className="text-3xl font-bold text-muted-foreground">$</span>
          <Input
            type="text"
            inputMode="decimal"
            value={amount}
            onChange={(e) => handleAmountChange(e.target.value)}
            placeholder="0.00"
            className="text-3xl font-bold h-14 border-none shadow-none focus-visible:ring-0 bg-transparent"
          />
        </div>
      </Card>

      {/* Type Selector */}
      <div className="flex gap-3 mx-4 mb-4">
        <Button
          variant={type === 'expense' ? 'default' : 'outline'}
          onClick={() => setType('expense')}
          className={cn(
            "flex-1 h-12 text-lg font-semibold transition-all",
            type === 'expense' && "gradient-danger"
          )}
        >
          <Minus className="w-5 h-5 mr-2" />
          Gasto
        </Button>
        <Button
          variant={type === 'income' ? 'default' : 'outline'}
          onClick={() => setType('income')}
          className={cn(
            "flex-1 h-12 text-lg font-semibold transition-all",
            type === 'income' && "gradient-success"
          )}
        >
          <Plus className="w-5 h-5 mr-2" />
          Ingreso
        </Button>
      </div>

      {/* Emoji Keyboard */}
      <Card className="mx-4 p-4 mb-4 shadow-lg flex-1 overflow-auto">
        <p className="text-sm text-muted-foreground mb-3">Selecciona una categoría</p>
        <div className="grid grid-cols-4 gap-3">
          {displayCategories.map((category) => (
            <button
              key={category.id}
              onClick={() => setSelectedCategory(category.id)}
              className={cn(
                "text-4xl p-3 rounded-xl transition-all duration-200 hover:scale-110",
                selectedCategory === category.id
                  ? "bg-primary/20 ring-2 ring-primary scale-110 shadow-lg"
                  : "bg-muted hover:bg-muted/80"
              )}
              title={category.description}
            >
              {category.emoji}
            </button>
          ))}
        </div>
        {selectedCategory && (
          <p className="text-center mt-3 text-sm text-muted-foreground animate-slide-up">
            {categories.find(c => c.id === selectedCategory)?.description}
          </p>
        )}
      </Card>

      {/* Payment Method Buttons */}
      <div className="flex gap-3 mx-4 mb-2">
        <Button
          onClick={() => handleSubmit('cash')}
          disabled={!canSubmit}
          className="flex-1 h-14 text-lg font-semibold gradient-accent text-accent-foreground hover:opacity-90 transition-opacity"
        >
          <Banknote className="w-6 h-6 mr-2" />
          💵 Cash
        </Button>
        <Button
          onClick={() => cards.length > 0 ? setShowCardSelector(true) : null}
          disabled={!canSubmit || cards.length === 0}
          className="flex-1 h-14 text-lg font-semibold gradient-secondary hover:opacity-90 transition-opacity"
        >
          <CreditCard className="w-6 h-6 mr-2" />
          💳 Tarjeta
        </Button>
      </div>

      {/* Pay Credit Card Button */}
      {creditCardsWithDebt.some(c => c.debt > 0) && (
        <div className="mx-4 mb-4">
          <Button
            onClick={() => setShowPayCardSelector(true)}
            disabled={!canPayCard}
            variant="outline"
            className="w-full h-12 text-base font-medium border-primary/50 hover:bg-primary/10"
          >
            💰 Pagar Tarjeta de Crédito
          </Button>
        </div>
      )}

      {cards.length === 0 && (
        <p className="text-center text-xs text-muted-foreground mx-4 mb-4">
          Ve a Ajustes para agregar tus tarjetas
        </p>
      )}

      {/* Card Selector Dialog */}
      <Dialog open={showCardSelector} onOpenChange={setShowCardSelector}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle className="text-center">Selecciona una tarjeta</DialogTitle>
          </DialogHeader>
          <div className="grid gap-3 py-4">
            {cards.map((card) => (
              <Button
                key={card.id}
                variant="outline"
                onClick={() => handleSubmit(card.id)}
                className="h-16 justify-start text-left"
              >
                <span className="text-2xl mr-3">{card.colorEmoji}</span>
                <div className="flex-1">
                  <p className="font-semibold">{card.name}</p>
                  <p className="text-xs text-muted-foreground">
                    {card.type === 'credit' ? '🔴 Crédito (se suma a deuda)' : '🟢 Débito'}
                  </p>
                </div>
              </Button>
            ))}
          </div>
        </DialogContent>
      </Dialog>

      {/* Pay Card Selector Dialog */}
      <Dialog open={showPayCardSelector} onOpenChange={setShowPayCardSelector}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle className="text-center">¿Cuál tarjeta pagarás?</DialogTitle>
          </DialogHeader>
          <div className="grid gap-3 py-4">
            {creditCardsWithDebt.filter(c => c.debt > 0).map((card) => (
              <Button
                key={card.id}
                variant="outline"
                onClick={() => handlePayCard(card.id)}
                className="h-16 justify-between text-left"
              >
                <div className="flex items-center gap-3">
                  <span className="text-2xl">{card.colorEmoji}</span>
                  <div>
                    <p className="font-semibold">{card.name}</p>
                    <p className="text-xs text-muted-foreground">Crédito</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-xs text-muted-foreground">Deuda</p>
                  <p className="font-bold text-destructive">
                    ${card.debt.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
                  </p>
                </div>
              </Button>
            ))}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

import { Trash2 } from 'lucide-react';
import { Virtuoso } from 'react-virtuoso';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useFinance } from '@/contexts/FinanceContext';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { Transaction } from '@/types/finance';

export function HistoryScreen() {
  const { 
    transactions, 
    balance,
    totalCreditDebt: totalDebt,
    getCategoryById, 
    getCardById, 
    deleteTransaction 
  } = useFinance();

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return format(date, "d 'de' MMM, HH:mm", { locale: es });
  };

  const getPaymentMethodDisplay = (transaction: Transaction) => {
    if (transaction.type === 'credit_payment') {
      const targetCard = getCardById(transaction.targetCardId || '');
      return { 
        emoji: targetCard?.colorEmoji || '💳', 
        label: `Pago a ${targetCard?.name || 'Tarjeta'}` 
      };
    }
    if (transaction.paymentMethod === 'cash') {
      return { emoji: '💵', label: 'Efectivo' };
    }
    const card = getCardById(transaction.paymentMethod);
    return { emoji: card?.colorEmoji || '💳', label: card?.name || 'Tarjeta' };
  };

  const getAmountColor = (transaction: Transaction) => {
    switch (transaction.type) {
      case 'income':
        return 'text-success';
      case 'expense':
      case 'credit_payment':
        return 'text-destructive';
      case 'credit_expense':
        return 'text-orange-500'; // Different color for credit purchases
      default:
        return 'text-foreground';
    }
  };

  const getAmountPrefix = (transaction: Transaction) => {
    switch (transaction.type) {
      case 'income':
        return '+';
      case 'expense':
      case 'credit_payment':
        return '-';
      case 'credit_expense':
        return '🔴 '; // Indicates it's credit debt
      default:
        return '';
    }
  };

  const getTransactionBadge = (transaction: Transaction) => {
    if (transaction.type === 'credit_expense') {
      return (
        <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-orange-500/20 text-orange-600 font-medium">
          CRÉDITO
        </span>
      );
    }
    if (transaction.type === 'credit_payment') {
      return (
        <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-primary/20 text-primary font-medium">
          PAGO
        </span>
      );
    }
    return null;
  };

  return (
    <div className="flex flex-col h-full pb-20">
      {/* Balance Header */}
      <div className="text-center py-4 sticky top-0 bg-background/80 backdrop-blur-sm z-10">
        <p className="text-sm text-muted-foreground mb-1">Balance Disponible</p>
        <h1 className={cn(
          "text-4xl font-bold transition-colors",
          balance >= 0 ? "text-success" : "text-destructive"
        )}>
          ${balance.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
        </h1>
        
        {totalDebt > 0 && (
          <div className="mt-2 flex items-center justify-center gap-2">
            <span className="text-sm text-muted-foreground">Deuda en tarjetas:</span>
            <span className="text-sm font-semibold text-orange-500">
              ${totalDebt.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
            </span>
          </div>
        )}
      </div>

      {/* Transactions List */}
      <div className="flex-1 min-h-0 px-4">
        {transactions.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-6xl mb-4">📝</p>
            <p className="text-muted-foreground">No hay transacciones aún</p>
            <p className="text-sm text-muted-foreground mt-1">
              Agrega tu primera transacción en la calculadora
            </p>
          </div>
        ) : (
          <Virtuoso
            style={{ height: '100%' }}
            data={transactions}
            itemContent={(index, transaction) => {
              const category = getCategoryById(transaction.categoryId);
              const paymentMethod = getPaymentMethodDisplay(transaction);
              const badge = getTransactionBadge(transaction);

              return (
                <div className="pb-3">
                  <Card
                    className={cn(
                      "p-4 flex items-center gap-4 animate-slide-up shadow-md hover:shadow-lg transition-shadow",
                      transaction.type === 'credit_expense' && "border-orange-500/30"
                    )}
                    style={{ animationDelay: `${index < 10 ? index * 50 : 0}ms` }}
                  >
                    {/* Emoji */}
                    <div className="text-4xl">{category?.emoji || '❓'}</div>

                    {/* Details */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="font-medium truncate">
                          {category?.description || 'Sin categoría'}
                        </p>
                        {badge}
                      </div>
                      <div className="flex items-center gap-2 text-xs text-muted-foreground">
                        <span>{paymentMethod.emoji}</span>
                        <span>{paymentMethod.label}</span>
                        <span>•</span>
                        <span>{formatDate(transaction.date)}</span>
                      </div>
                    </div>

                    {/* Amount */}
                    <div className={cn(
                      "text-lg font-bold whitespace-nowrap",
                      getAmountColor(transaction)
                    )}>
                      {getAmountPrefix(transaction)}$
                      {transaction.amount.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
                    </div>

                    {/* Delete Button */}
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => deleteTransaction(transaction.id)}
                      className="text-muted-foreground hover:text-destructive hover:bg-destructive/10"
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </Card>
                </div>
              );
            }}
          />
        )}
      </div>
    </div>
  );
}

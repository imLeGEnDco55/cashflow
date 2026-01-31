import { Trash2, Banknote, CreditCard } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useFinance } from '@/contexts/FinanceContext';
import { cn } from '@/lib/utils';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

export function HistoryScreen() {
  const { transactions, getBalance, getCategoryById, getCardById, deleteTransaction } = useFinance();

  const balance = getBalance();

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return format(date, "d 'de' MMM, HH:mm", { locale: es });
  };

  const getPaymentMethodDisplay = (paymentMethod: string) => {
    if (paymentMethod === 'cash') {
      return { icon: Banknote, label: 'Efectivo' };
    }
    const card = getCardById(paymentMethod);
    return { icon: CreditCard, label: card?.name || 'Tarjeta' };
  };

  return (
    <div className="flex flex-col h-full pb-20">
      {/* Balance Header */}
      <div className="text-center py-6 sticky top-0 bg-background/80 backdrop-blur-sm z-10">
        <p className="text-sm text-muted-foreground mb-1">Balance Actual</p>
        <h1 className={cn(
          "text-4xl font-bold transition-colors",
          balance >= 0 ? "text-success" : "text-destructive"
        )}>
          ${balance.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
        </h1>
      </div>

      {/* Transactions List */}
      <div className="flex-1 overflow-auto px-4">
        {transactions.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-6xl mb-4">📝</p>
            <p className="text-muted-foreground">No hay transacciones aún</p>
            <p className="text-sm text-muted-foreground mt-1">
              Agrega tu primera transacción en la calculadora
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {transactions.map((transaction, index) => {
              const category = getCategoryById(transaction.categoryId);
              const paymentMethod = getPaymentMethodDisplay(transaction.paymentMethod);
              const PaymentIcon = paymentMethod.icon;

              return (
                <Card
                  key={transaction.id}
                  className="p-4 flex items-center gap-4 animate-slide-up shadow-md hover:shadow-lg transition-shadow"
                  style={{ animationDelay: `${index * 50}ms` }}
                >
                  {/* Emoji */}
                  <div className="text-4xl">{category?.emoji || '❓'}</div>

                  {/* Details */}
                  <div className="flex-1 min-w-0">
                    <p className="font-medium truncate">
                      {category?.description || 'Sin categoría'}
                    </p>
                    <div className="flex items-center gap-2 text-xs text-muted-foreground">
                      <PaymentIcon className="w-3 h-3" />
                      <span>{paymentMethod.label}</span>
                      <span>•</span>
                      <span>{formatDate(transaction.date)}</span>
                    </div>
                  </div>

                  {/* Amount */}
                  <div className={cn(
                    "text-lg font-bold whitespace-nowrap",
                    transaction.type === 'income' ? "text-success" : "text-destructive"
                  )}>
                    {transaction.type === 'income' ? '+' : '-'}$
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
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

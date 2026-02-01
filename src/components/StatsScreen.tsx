import { useState, useMemo } from 'react';
import { Card } from '@/components/ui/card';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useFinance } from '@/contexts/FinanceContext';
import { cn } from '@/lib/utils';
import {
  startOfWeek,
  endOfWeek,
  startOfMonth,
  endOfMonth,
  startOfYear,
  endOfYear,
  isWithinInterval,
} from 'date-fns';
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from '@/components/ui/chart';
import { PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, ResponsiveContainer } from 'recharts';

type Period = 'week' | 'month' | 'year' | 'all';
type ViewType = 'all' | 'income' | 'expense';

const COLORS = [
  'hsl(280, 70%, 55%)',
  'hsl(180, 60%, 50%)',
  'hsl(35, 95%, 60%)',
  'hsl(145, 65%, 42%)',
  'hsl(0, 75%, 55%)',
  'hsl(200, 70%, 55%)',
  'hsl(320, 70%, 60%)',
  'hsl(60, 80%, 50%)',
];

export function StatsScreen() {
  const { transactions, categories, getCategoryById, totalCreditDebt: totalDebt, creditCardsWithDebt } = useFinance();
  const [period, setPeriod] = useState<Period>('month');
  const [viewType, setViewType] = useState<ViewType>('all');

  const filteredTransactions = useMemo(() => {
    const now = new Date();
    let startDate: Date;
    let endDate: Date;

    switch (period) {
      case 'week':
        startDate = startOfWeek(now, { weekStartsOn: 1 });
        endDate = endOfWeek(now, { weekStartsOn: 1 });
        break;
      case 'month':
        startDate = startOfMonth(now);
        endDate = endOfMonth(now);
        break;
      case 'year':
        startDate = startOfYear(now);
        endDate = endOfYear(now);
        break;
      default:
        return transactions.filter(t => {
          if (viewType === 'all') return true;
          if (viewType === 'income') return t.type === 'income';
          // For expenses, include both real expenses and credit expenses
          return t.type === 'expense' || t.type === 'credit_expense';
        });
    }

    return transactions.filter(t => {
      const date = new Date(t.date);
      const inPeriod = isWithinInterval(date, { start: startDate, end: endDate });
      if (!inPeriod) return false;

      if (viewType === 'all') return true;
      if (viewType === 'income') return t.type === 'income';
      return t.type === 'expense' || t.type === 'credit_expense';
    });
  }, [transactions, period, viewType]);

  const categoryStats = useMemo(() => {
    const stats: Record<string, { total: number; count: number; category: typeof categories[0] }> = {};

    filteredTransactions.forEach(t => {
      const category = getCategoryById(t.categoryId);
      if (!category) return;

      if (!stats[t.categoryId]) {
        stats[t.categoryId] = { total: 0, count: 0, category };
      }
      stats[t.categoryId].total += t.amount;
      stats[t.categoryId].count += 1;
    });

    return Object.values(stats)
      .sort((a, b) => b.total - a.total)
      .map((stat, index) => ({
        ...stat,
        color: COLORS[index % COLORS.length],
      }));
  }, [filteredTransactions, getCategoryById]);

  const totals = useMemo(() => {
    const income = filteredTransactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + t.amount, 0);
    // Real expenses (cash/debit)
    const realExpense = filteredTransactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
    // Credit expenses (debt)
    const creditExpense = filteredTransactions
      .filter(t => t.type === 'credit_expense')
      .reduce((sum, t) => sum + t.amount, 0);
    const totalExpense = realExpense + creditExpense;
    return { income, realExpense, creditExpense, totalExpense, balance: income - realExpense };
  }, [filteredTransactions]);

  const pieData = categoryStats.map(stat => ({
    name: stat.category.emoji,
    value: stat.total,
    fill: stat.color,
  }));

  const barData = [
    { name: 'Ingresos', value: totals.income, fill: 'hsl(145, 65%, 42%)' },
    { name: 'Gastos', value: totals.realExpense, fill: 'hsl(0, 75%, 55%)' },
    { name: 'Crédito', value: totals.creditExpense, fill: 'hsl(30, 90%, 55%)' },
  ];

  const chartConfig = {
    value: { label: 'Monto' },
  };

  return (
    <div className="flex flex-col h-full pb-20 overflow-auto">
      <div className="p-4 space-y-4">
        {/* Filters Row */}
        <div className="flex gap-3">
          <Select value={period} onValueChange={(v) => setPeriod(v as Period)}>
            <SelectTrigger className="flex-1">
              <SelectValue placeholder="Período" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="week">📅 Semana</SelectItem>
              <SelectItem value="month">📆 Mes</SelectItem>
              <SelectItem value="year">🗓️ Año</SelectItem>
              <SelectItem value="all">📊 Todo</SelectItem>
            </SelectContent>
          </Select>

          <Select value={viewType} onValueChange={(v) => setViewType(v as ViewType)}>
            <SelectTrigger className="flex-1">
              <SelectValue placeholder="Tipo" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">🔄 Todo</SelectItem>
              <SelectItem value="income">📈 Ingresos</SelectItem>
              <SelectItem value="expense">📉 Gastos</SelectItem>
            </SelectContent>
          </Select>
        </div>


        {/* Summary Cards */}
        <div className="grid grid-cols-2 gap-3">
          <Card className="p-3 text-center gradient-success text-success-foreground">
            <p className="text-xs opacity-80">Ingresos</p>
            <p className="font-bold text-lg">
              ${totals.income.toLocaleString('es-MX', { maximumFractionDigits: 0 })}
            </p>
          </Card>
          <Card className="p-3 text-center gradient-danger text-destructive-foreground">
            <p className="text-xs opacity-80">Gastos (Efectivo)</p>
            <p className="font-bold text-lg">
              ${totals.realExpense.toLocaleString('es-MX', { maximumFractionDigits: 0 })}
            </p>
          </Card>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <Card className="p-3 text-center bg-orange-500 text-white">
            <p className="text-xs opacity-80">Gastos (Crédito)</p>
            <p className="font-bold text-lg">
              ${totals.creditExpense.toLocaleString('es-MX', { maximumFractionDigits: 0 })}
            </p>
          </Card>
          <Card className={cn(
            "p-3 text-center",
            totals.balance >= 0 ? "gradient-secondary" : "gradient-danger",
            "text-primary-foreground"
          )}>
            <p className="text-xs opacity-80">Balance Real</p>
            <p className="font-bold text-lg">
              ${totals.balance.toLocaleString('es-MX', { maximumFractionDigits: 0 })}
            </p>
          </Card>
        </div>

        {/* Credit Card Debt Summary */}
        {/* Credit Card Debt Summary */}
        {creditCardsWithDebt.length > 0 && (
          <Card className="p-4 shadow-lg border-orange-500/30">
            <h3 className="font-semibold mb-3 flex items-center gap-2">
              💳 Tarjetas de Crédito
            </h3>
            <div className="space-y-3">
              {creditCardsWithDebt.map((card) => (
                <div key={card.id} className="p-3 rounded-lg bg-muted/50">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <span className="text-xl">{card.colorEmoji}</span>
                      <span className="font-medium">{card.name}</span>
                    </div>
                    <span className={cn(
                      "font-bold",
                      card.debt > 0 ? "text-orange-500" : "text-success"
                    )}>
                      ${card.debt.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
                    </span>
                  </div>
                  {card.cutOffDay && card.paymentDay && (
                    <div className="flex gap-4 text-xs text-muted-foreground">
                      <span className="flex items-center gap-1">
                        ✂️ Corte: día {card.cutOffDay}
                      </span>
                      <span className="flex items-center gap-1">
                        📅 Pago: día {card.paymentDay}
                      </span>
                    </div>
                  )}
                </div>
              ))}
              {totalDebt > 0 && (
                <div className="border-t pt-3 mt-2 flex justify-between font-semibold">
                  <span>Total Deuda</span>
                  <span className="text-orange-500">
                    ${totalDebt.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
                  </span>
                </div>
              )}
            </div>
          </Card>
        )}

        {filteredTransactions.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-6xl mb-4">📊</p>
            <p className="text-muted-foreground">No hay datos para este período</p>
          </div>
        ) : (
          <>
            {/* Bar Chart */}
            <Card className="p-4 shadow-lg">
              <h3 className="font-semibold mb-4 text-center">Ingresos vs Gastos</h3>
              <ChartContainer config={chartConfig} className="h-48">
                <BarChart data={barData}>
                  <XAxis dataKey="name" />
                  <YAxis />
                  <ChartTooltip content={<ChartTooltipContent />} />
                  <Bar dataKey="value" radius={[8, 8, 0, 0]}>
                    {barData.map((entry, index) => (
                      <Cell key={index} fill={entry.fill} />
                    ))}
                  </Bar>
                </BarChart>
              </ChartContainer>
            </Card>

            {/* Pie Chart */}
            {pieData.length > 0 && (
              <Card className="p-4 shadow-lg">
                <h3 className="font-semibold mb-4 text-center">Por Categoría</h3>
                <ChartContainer config={chartConfig} className="h-64">
                  <PieChart>
                    <Pie
                      data={pieData}
                      cx="50%"
                      cy="50%"
                      outerRadius={80}
                      dataKey="value"
                      label={({ name, percent }) =>
                        `${name} ${(percent * 100).toFixed(0)}%`
                      }
                    >
                      {pieData.map((entry, index) => (
                        <Cell key={index} fill={entry.fill} />
                      ))}
                    </Pie>
                    <ChartTooltip content={<ChartTooltipContent />} />
                  </PieChart>
                </ChartContainer>
              </Card>
            )}

            {/* Category List */}
            <Card className="p-4 shadow-lg">
              <h3 className="font-semibold mb-4">Totales por Categoría</h3>
              <div className="space-y-3">
                {categoryStats.map((stat) => (
                  <div
                    key={stat.category.id}
                    className="flex items-center gap-3"
                  >
                    <span className="text-3xl">{stat.category.emoji}</span>
                    <div className="flex-1">
                      <p className="font-medium">{stat.category.description}</p>
                      <p className="text-xs text-muted-foreground">
                        {stat.count} transacción{stat.count !== 1 ? 'es' : ''}
                      </p>
                    </div>
                    <p className="font-bold" style={{ color: stat.color }}>
                      ${stat.total.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
                    </p>
                  </div>
                ))}
              </div>
            </Card>
          </>
        )}
      </div>
    </div>
  );
}

import { useState, useMemo } from 'react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
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
  const { transactions, categories, getCategoryById } = useFinance();
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
        return transactions.filter(t => 
          viewType === 'all' || t.type === viewType
        );
    }

    return transactions.filter(t => {
      const date = new Date(t.date);
      const inPeriod = isWithinInterval(date, { start: startDate, end: endDate });
      const matchesType = viewType === 'all' || t.type === viewType;
      return inPeriod && matchesType;
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
    const expense = filteredTransactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + t.amount, 0);
    return { income, expense, balance: income - expense };
  }, [filteredTransactions]);

  const pieData = categoryStats.map(stat => ({
    name: stat.category.emoji,
    value: stat.total,
    fill: stat.color,
  }));

  const barData = [
    { name: 'Ingresos', value: totals.income, fill: 'hsl(145, 65%, 42%)' },
    { name: 'Gastos', value: totals.expense, fill: 'hsl(0, 75%, 55%)' },
  ];

  const chartConfig = {
    value: { label: 'Monto' },
  };

  return (
    <div className="flex flex-col h-full pb-20 overflow-auto">
      <div className="p-4 space-y-4">
        {/* Period Filter */}
        <div className="flex gap-2 overflow-x-auto pb-2">
          {[
            { id: 'week' as Period, label: 'Semana' },
            { id: 'month' as Period, label: 'Mes' },
            { id: 'year' as Period, label: 'Año' },
            { id: 'all' as Period, label: 'Todo' },
          ].map(({ id, label }) => (
            <Button
              key={id}
              variant={period === id ? 'default' : 'outline'}
              onClick={() => setPeriod(id)}
              className={cn(
                "whitespace-nowrap",
                period === id && "gradient-primary"
              )}
            >
              {label}
            </Button>
          ))}
        </div>

        {/* View Type Filter */}
        <div className="flex gap-2">
          {[
            { id: 'all' as ViewType, label: 'Todo' },
            { id: 'income' as ViewType, label: '📈 Ingresos' },
            { id: 'expense' as ViewType, label: '📉 Gastos' },
          ].map(({ id, label }) => (
            <Button
              key={id}
              variant={viewType === id ? 'default' : 'outline'}
              size="sm"
              onClick={() => setViewType(id)}
            >
              {label}
            </Button>
          ))}
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-3 gap-3">
          <Card className="p-3 text-center gradient-success text-success-foreground">
            <p className="text-xs opacity-80">Ingresos</p>
            <p className="font-bold text-lg">
              ${totals.income.toLocaleString('es-MX', { maximumFractionDigits: 0 })}
            </p>
          </Card>
          <Card className="p-3 text-center gradient-danger text-destructive-foreground">
            <p className="text-xs opacity-80">Gastos</p>
            <p className="font-bold text-lg">
              ${totals.expense.toLocaleString('es-MX', { maximumFractionDigits: 0 })}
            </p>
          </Card>
          <Card className={cn(
            "p-3 text-center",
            totals.balance >= 0 ? "gradient-secondary" : "gradient-danger",
            "text-primary-foreground"
          )}>
            <p className="text-xs opacity-80">Balance</p>
            <p className="font-bold text-lg">
              ${totals.balance.toLocaleString('es-MX', { maximumFractionDigits: 0 })}
            </p>
          </Card>
        </div>

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

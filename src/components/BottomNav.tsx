import { useState } from 'react';
import { Calculator, History, BarChart3, Settings } from 'lucide-react';
import { cn } from '@/lib/utils';

type Tab = 'calculator' | 'history' | 'stats' | 'settings';

interface BottomNavProps {
  activeTab: Tab;
  onTabChange: (tab: Tab) => void;
}

const tabs = [
  { id: 'calculator' as Tab, icon: Calculator, label: 'Calculadora' },
  { id: 'history' as Tab, icon: History, label: 'Historial' },
  { id: 'stats' as Tab, icon: BarChart3, label: 'Estadísticas' },
  { id: 'settings' as Tab, icon: Settings, label: 'Ajustes' },
];

export function BottomNav({ activeTab, onTabChange }: BottomNavProps) {
  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-card/95 backdrop-blur-lg border-t border-border shadow-lg">
      <div className="flex justify-around items-center h-16 max-w-lg mx-auto px-2">
        {tabs.map(({ id, icon: Icon, label }) => (
          <button
            key={id}
            onClick={() => onTabChange(id)}
            className={cn(
              "flex flex-col items-center justify-center py-2 px-4 rounded-xl transition-all duration-200",
              activeTab === id
                ? "gradient-primary text-primary-foreground scale-105 shadow-md"
                : "text-muted-foreground hover:text-foreground hover:bg-muted"
            )}
          >
            <Icon className="w-5 h-5 mb-0.5" />
            <span className="text-xs font-medium">{label}</span>
          </button>
        ))}
      </div>
    </nav>
  );
}

export type { Tab };

import { useState } from 'react';
import { FinanceProvider } from '@/contexts/FinanceContext';
import { BottomNav, Tab } from '@/components/BottomNav';
import { CalculatorScreen } from '@/components/CalculatorScreen';
import { HistoryScreen } from '@/components/HistoryScreen';
import { StatsScreen } from '@/components/StatsScreen';
import { SettingsScreen } from '@/components/SettingsScreen';

const Index = () => {
  const [activeTab, setActiveTab] = useState<Tab>('calculator');

  const renderScreen = () => {
    switch (activeTab) {
      case 'calculator':
        return <CalculatorScreen />;
      case 'history':
        return <HistoryScreen />;
      case 'stats':
        return <StatsScreen />;
      case 'settings':
        return <SettingsScreen />;
    }
  };

  return (
    <FinanceProvider>
      <div className="min-h-screen max-w-lg mx-auto">
        {renderScreen()}
        <BottomNav activeTab={activeTab} onTabChange={setActiveTab} />
      </div>
    </FinanceProvider>
  );
};

export default Index;

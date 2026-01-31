import { useState } from 'react';
import { Plus, Trash2, Edit2, CreditCard, Download, Upload, Check, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { useFinance } from '@/contexts/FinanceContext';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { cn } from '@/lib/utils';

export function SettingsScreen() {
  const {
    categories,
    cards,
    addCategory,
    updateCategory,
    deleteCategory,
    addCard,
    updateCard,
    deleteCard,
    exportData,
    importData,
  } = useFinance();

  const [newEmoji, setNewEmoji] = useState('');
  const [newDescription, setNewDescription] = useState('');
  const [newCardName, setNewCardName] = useState('');
  const [newCardType, setNewCardType] = useState<'credit' | 'debit'>('debit');
  const [editingCategory, setEditingCategory] = useState<string | null>(null);
  const [editingCard, setEditingCard] = useState<string | null>(null);
  const [editValue, setEditValue] = useState('');
  const [showAddCategory, setShowAddCategory] = useState(false);
  const [showAddCard, setShowAddCard] = useState(false);

  const handleAddCategory = () => {
    if (!newEmoji || !newDescription) return;
    addCategory({ emoji: newEmoji, description: newDescription });
    setNewEmoji('');
    setNewDescription('');
    setShowAddCategory(false);
  };

  const handleAddCard = () => {
    if (!newCardName) return;
    addCard({ name: newCardName, type: newCardType });
    setNewCardName('');
    setNewCardType('debit');
    setShowAddCard(false);
  };

  const handleImport = () => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (file) importData(file);
    };
    input.click();
  };

  return (
    <div className="flex flex-col h-full pb-20 overflow-auto">
      <div className="p-4 space-y-6">
        <h1 className="text-2xl font-bold text-center">⚙️ Ajustes</h1>

        {/* Categories Section */}
        <Card className="p-4 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold">🏷️ Categorías</h2>
            <Dialog open={showAddCategory} onOpenChange={setShowAddCategory}>
              <DialogTrigger asChild>
                <Button size="sm" className="gradient-primary">
                  <Plus className="w-4 h-4 mr-1" />
                  Agregar
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-sm">
                <DialogHeader>
                  <DialogTitle>Nueva Categoría</DialogTitle>
                </DialogHeader>
                <div className="space-y-4 py-4">
                  <div>
                    <label className="text-sm text-muted-foreground">Emoji</label>
                    <Input
                      value={newEmoji}
                      onChange={(e) => setNewEmoji(e.target.value)}
                      placeholder="🎉"
                      className="text-2xl text-center"
                      maxLength={2}
                    />
                  </div>
                  <div>
                    <label className="text-sm text-muted-foreground">Descripción</label>
                    <Input
                      value={newDescription}
                      onChange={(e) => setNewDescription(e.target.value)}
                      placeholder="Fiestas y celebraciones"
                    />
                  </div>
                  <Button onClick={handleAddCategory} className="w-full gradient-primary">
                    Agregar Categoría
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          </div>

          <div className="space-y-2">
            {categories.map((category) => (
              <div
                key={category.id}
                className="flex items-center gap-3 p-2 rounded-lg bg-muted/50"
              >
                <span className="text-2xl">{category.emoji}</span>
                {editingCategory === category.id ? (
                  <>
                    <Input
                      value={editValue}
                      onChange={(e) => setEditValue(e.target.value)}
                      className="flex-1 h-8"
                      autoFocus
                    />
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => {
                        updateCategory(category.id, { description: editValue });
                        setEditingCategory(null);
                      }}
                      className="h-8 w-8 text-success"
                    >
                      <Check className="w-4 h-4" />
                    </Button>
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => setEditingCategory(null)}
                      className="h-8 w-8"
                    >
                      <X className="w-4 h-4" />
                    </Button>
                  </>
                ) : (
                  <>
                    <span className="flex-1 text-sm">{category.description}</span>
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => {
                        setEditingCategory(category.id);
                        setEditValue(category.description);
                      }}
                      className="h-8 w-8"
                    >
                      <Edit2 className="w-4 h-4" />
                    </Button>
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => deleteCategory(category.id)}
                      className="h-8 w-8 text-destructive hover:text-destructive"
                    >
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </>
                )}
              </div>
            ))}
          </div>
        </Card>

        {/* Cards Section */}
        <Card className="p-4 shadow-lg">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold">💳 Tarjetas</h2>
            <Dialog open={showAddCard} onOpenChange={setShowAddCard}>
              <DialogTrigger asChild>
                <Button size="sm" className="gradient-secondary">
                  <Plus className="w-4 h-4 mr-1" />
                  Agregar
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-sm">
                <DialogHeader>
                  <DialogTitle>Nueva Tarjeta</DialogTitle>
                </DialogHeader>
                <div className="space-y-4 py-4">
                  <div>
                    <label className="text-sm text-muted-foreground">Nombre</label>
                    <Input
                      value={newCardName}
                      onChange={(e) => setNewCardName(e.target.value)}
                      placeholder="BBVA Oro"
                    />
                  </div>
                  <div>
                    <label className="text-sm text-muted-foreground">Tipo</label>
                    <Select value={newCardType} onValueChange={(v) => setNewCardType(v as 'credit' | 'debit')}>
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="debit">Débito</SelectItem>
                        <SelectItem value="credit">Crédito</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <Button onClick={handleAddCard} className="w-full gradient-secondary">
                    Agregar Tarjeta
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          </div>

          {cards.length === 0 ? (
            <p className="text-center text-muted-foreground py-4">
              No tienes tarjetas configuradas
            </p>
          ) : (
            <div className="space-y-2">
              {cards.map((card) => (
                <div
                  key={card.id}
                  className="flex items-center gap-3 p-3 rounded-lg bg-muted/50"
                >
                  <CreditCard className="w-5 h-5 text-primary" />
                  {editingCard === card.id ? (
                    <>
                      <Input
                        value={editValue}
                        onChange={(e) => setEditValue(e.target.value)}
                        className="flex-1 h-8"
                        autoFocus
                      />
                      <Button
                        size="icon"
                        variant="ghost"
                        onClick={() => {
                          updateCard(card.id, { name: editValue });
                          setEditingCard(null);
                        }}
                        className="h-8 w-8 text-success"
                      >
                        <Check className="w-4 h-4" />
                      </Button>
                      <Button
                        size="icon"
                        variant="ghost"
                        onClick={() => setEditingCard(null)}
                        className="h-8 w-8"
                      >
                        <X className="w-4 h-4" />
                      </Button>
                    </>
                  ) : (
                    <>
                      <div className="flex-1">
                        <p className="font-medium">{card.name}</p>
                        <p className="text-xs text-muted-foreground">
                          {card.type === 'credit' ? 'Crédito' : 'Débito'}
                        </p>
                      </div>
                      <Button
                        size="icon"
                        variant="ghost"
                        onClick={() => {
                          setEditingCard(card.id);
                          setEditValue(card.name);
                        }}
                        className="h-8 w-8"
                      >
                        <Edit2 className="w-4 h-4" />
                      </Button>
                      <Button
                        size="icon"
                        variant="ghost"
                        onClick={() => deleteCard(card.id)}
                        className="h-8 w-8 text-destructive hover:text-destructive"
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </>
                  )}
                </div>
              ))}
            </div>
          )}
        </Card>

        {/* Backup Section */}
        <Card className="p-4 shadow-lg">
          <h2 className="text-lg font-semibold mb-4">💾 Respaldo</h2>
          <div className="flex gap-3">
            <Button
              variant="outline"
              onClick={exportData}
              className="flex-1"
            >
              <Download className="w-4 h-4 mr-2" />
              Exportar
            </Button>
            <Button
              variant="outline"
              onClick={handleImport}
              className="flex-1"
            >
              <Upload className="w-4 h-4 mr-2" />
              Importar
            </Button>
          </div>
        </Card>
      </div>
    </div>
  );
}

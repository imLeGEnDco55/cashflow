/// CashFlow - Personal Finance Manager
/// Flutter native app translated from React/Vite
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'widgets/glow_bottom_bar.dart';

import 'providers/finance_provider.dart';
import 'screens/calculator_screen.dart';
import 'screens/history_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Spanish
  await initializeDateFormatting('es', null);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const CashFlowApp());
}

class CashFlowApp extends StatelessWidget {
  const CashFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider()..loadData(),
      child: MaterialApp(
        title: 'CashFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _screens = [
    const CalculatorScreen(),
    const HistoryScreen(),
    const CardsScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'CashFlow',
    'Historial',
    'Tarjetas',
    'Estadísticas',
    'Ajustes',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando...',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          );
        }

        final goingRight = _currentIndex > _previousIndex;

        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _titles[_currentIndex],
                key: ValueKey(_currentIndex),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final isIncoming = child.key == ValueKey(_currentIndex);
              final slideOffset = Tween<Offset>(
                begin: Offset(
                  isIncoming
                      ? (goingRight ? 0.05 : -0.05)
                      : (goingRight ? -0.05 : 0.05),
                  0,
                ),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slideOffset, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _screens[_currentIndex],
            ),
          ),
          bottomNavigationBar: GlowBottomBar(
            currentIndex: _currentIndex,
            glowColor: AppTheme.primary,
            activeColor: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            onTap: (index) {
              HapticFeedback.selectionClick();
              setState(() {
                _previousIndex = _currentIndex;
                _currentIndex = index;
              });
            },
            icons: const [
              Icons.account_balance_wallet_outlined,
              Icons.history_outlined,
              Icons.credit_card_outlined,
              Icons.pie_chart_outline,
              Icons.settings_outlined,
            ],
            activeIcons: const [
              Icons.account_balance_wallet,
              Icons.history,
              Icons.credit_card,
              Icons.pie_chart,
              Icons.settings,
            ],
          ),
        );
      },
    );
  }
}

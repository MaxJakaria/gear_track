import 'package:flutter/material.dart';
import 'package:gear_track/feature/inventory/presentation/pages/inventory_page.dart';
import 'package:gear_track/feature/product_of_sales/presentation/pages/pos_page.dart';
import 'package:gear_track/presentation/pages/reports_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0; // Default to Inventory (Index 0)

  final List<Widget> _pages = const [InventoryPage(), PosPage(), ReportsPage()];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: isDark
              ? const Color(0xFF818CF8)
              : const Color(0xFF6366F1),
          unselectedItemColor: theme.colorScheme.onSurfaceVariant.withValues(
            alpha: 0.7,
          ),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart_rounded),
              label: 'Point of Sale',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insert_chart_outlined),
              activeIcon: Icon(Icons.insert_chart_rounded),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}

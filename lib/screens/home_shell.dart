import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ui_provider.dart';
import '../utils/theme.dart';
import 'home/home_screen.dart';
import 'map/map_screen.dart';
import 'search/search_screen.dart';
import 'timetable/timetable_screen.dart';
import 'profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const SearchScreen(),
    const TimetableScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = context.watch<UiProvider>().currentTabIndex;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.darkColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(context, 0, currentIndex, Icons.view_list_rounded, Icons.view_list_outlined),
              _buildNavItem(context, 1, currentIndex, Icons.map_rounded, Icons.map_outlined),
              _buildSearchItem(context),
              _buildNavItem(context, 3, currentIndex, Icons.calendar_month_rounded, Icons.calendar_month_outlined),
              _buildNavItem(context, 4, currentIndex, Icons.person_rounded, Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, int currentIndex, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        context.read<UiProvider>().setTabIndex(index);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? Colors.white : Colors.white.withAlpha(115),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildSearchItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<UiProvider>().setTabIndex(2);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.search_rounded,
          color: AppTheme.darkColor,
          size: 28,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:quran_app/core/di/injection.dart';
import 'package:quran_app/features/home/presentation/bloc/home_cubit.dart';
import 'package:quran_app/features/home/presentation/pages/home_page.dart';
import 'package:quran_app/features/quran/presentation/pages/quran_page.dart';
import 'package:quran_app/features/sholat/presentation/pages/sholat_page.dart';
import 'package:quran_app/features/doa/presentation/pages/doa_page.dart';
import 'package:quran_app/features/more/presentation/pages/more_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    BlocProvider(
      create: (_) => getIt<HomeCubit>()..fetchInitialData(),
      child: const HomePage(),
    ),
    const QuranPage(),
    const SholatPage(),
    const DoaPage(),
    const MorePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Al-Quran',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Sholat',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'Doa',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Lainnya',
          ),
        ],
      ),
    );
  }
}

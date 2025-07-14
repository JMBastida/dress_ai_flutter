import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'closet_screen.dart';
import 'import_url_screen.dart';

final List<String> _titles = [
  'closet'.tr(),
  'import'.tr(),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ClosetScreen(),
    ImportUrlScreen(),
    // Puedes agregar más pantallas aquí como: LooksScreen()
  ];

  final List<String> _titles = [
    'closet'.tr(),
    'import'.tr(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (newIndex) => setState(() => _currentIndex = newIndex),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.checkroom),
            label:  _titles[0],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.cloud_upload),
            label: _titles[1],
          ),
        ],
      ),
    );
  }
}

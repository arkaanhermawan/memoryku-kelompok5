// lib/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomNavigation({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.photo),
          label: 'Photos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books),
          label: 'Library',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.yellow,
      unselectedItemColor: Colors.white,
      backgroundColor: Colors.black,
      onTap: onItemTapped, // Menjaga agar halaman berubah sesuai pilihan
    );
  }
}

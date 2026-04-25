import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelperHomeLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HelperHomeLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF0D1120),
            selectedItemColor: const Color(0xFF6C63FF),
            unselectedItemColor: Colors.white38,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_rounded),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.language_rounded),
                label: 'Language',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

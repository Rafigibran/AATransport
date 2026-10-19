import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import 'home_screen.dart';
import '../booking/my_booking_screen.dart';
import 'favourites_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _index = widget.initialIndex;
  int _favouritesVersion = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const MyBookingScreen(),
      FavouritesScreen(key: ValueKey('favourites-$_favouritesVersion')),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          // Favourites is kept mounted by IndexedStack; rebuild it whenever
          // its tab becomes active so favourite changes made elsewhere are
          // never shown stale.
          if (i == 2) _favouritesVersion++;
        }),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.14),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: AppColors.primary),
              label: tr('nav_home')),
          NavigationDestination(
              icon: const Icon(Icons.confirmation_number_outlined),
              selectedIcon: const Icon(Icons.confirmation_number,
                  color: AppColors.primary),
              label: tr('nav_booking')),
          NavigationDestination(
              icon: const Icon(Icons.favorite_border),
              selectedIcon:
                  const Icon(Icons.favorite, color: AppColors.primary),
              label: tr('nav_fav')),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon:
                  const Icon(Icons.person, color: AppColors.primary),
              label: tr('nav_profile')),
        ],
      ),
    );
  }
}

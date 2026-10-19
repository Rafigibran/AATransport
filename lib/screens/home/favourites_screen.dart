import 'package:flutter/material.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/common_widgets.dart';
import 'car_details_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});
  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  late Future<List<Car>> _future = CarService.fetchFavourites();

  void _reload() => setState(() => _future = CarService.fetchFavourites());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('fav_title'))),
      body: FutureBuilder<List<Car>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
                message: tr('fav_fail'), onRetry: _reload);
          }
          final cars = snapshot.data ?? [];
          if (cars.isEmpty) {
            return ErrorView(message: tr('fav_empty'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: cars.length,
              itemBuilder: (_, i) => CarCard(
                car: cars[i],
                horizontal: true,
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CarDetailsScreen(car: cars[i])));
                  _reload();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

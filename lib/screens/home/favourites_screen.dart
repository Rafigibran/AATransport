import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../services/app_services.dart';
import '../../widgets/common_widgets.dart';
import 'hotel_details_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});
  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  late Future<List<Hotel>> _future = HotelService.fetchFavourites();

  void _reload() => setState(() => _future = HotelService.fetchFavourites());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: FutureBuilder<List<Hotel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const LoadingView();
          if (snapshot.hasError)
            return ErrorView(
                message: 'Gagal memuat favourites.', onRetry: _reload);
          final hotels = snapshot.data ?? [];
          if (hotels.isEmpty)
            return const ErrorView(
                message:
                    'Belum ada hotel favorit. Tekan ikon hati di detail hotel.');
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: hotels.length,
              itemBuilder: (_, i) => HotelCard(
                hotel: hotels[i],
                horizontal: true,
                onTap: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              HotelDetailsScreen(hotel: hotels[i])));
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

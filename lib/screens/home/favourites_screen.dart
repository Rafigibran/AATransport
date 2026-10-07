import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../widgets/common_widgets.dart';
import 'hotel_details_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final favs = MockData.hotels.where((h) => h.isFavourite).toList();
    final all = favs.isEmpty ? MockData.hotels.take(2).toList() : favs;
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: all.length,
        itemBuilder: (_, i) => HotelCard(
          hotel: all[i],
          horizontal: true,
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => HotelDetailsScreen(hotel: all[i]))),
        ),
      ),
    );
  }
}

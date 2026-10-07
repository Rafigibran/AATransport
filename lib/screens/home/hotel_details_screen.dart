import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/hotel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../booking/booking_info_screen.dart';

class HotelDetailsScreen extends StatelessWidget {
  final Hotel hotel;
  const HotelDetailsScreen({super.key, required this.hotel});

  IconData _facilityIcon(String f) {
    switch (f) {
      case 'Free Wifi':
        return Icons.wifi;
      case 'Restaurant':
        return Icons.restaurant;
      case 'Pool':
        return Icons.pool;
      case 'Gym':
        return Icons.fitness_center;
      case 'Spa':
        return Icons.spa;
      case 'Beach':
        return Icons.beach_access;
      default:
        return Icons.local_parking;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
                icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, size: 18)),
                onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(hotel.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade200)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(hotel.name,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold))),
                      IconButton(
                          onPressed: () {},
                          icon: Icon(
                              hotel.isFavourite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: hotel.isFavourite
                                  ? Colors.red
                                  : AppColors.textGrey)),
                    ],
                  ),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(hotel.location,
                        style: const TextStyle(color: AppColors.textGrey)),
                    const Spacer(),
                    const Icon(Icons.star, color: AppColors.star, size: 18),
                    const SizedBox(width: 4),
                    Text('${hotel.rating}  (${hotel.reviews} reviews)',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 22),
                  const Text('Facilities',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: hotel.facilities
                        .take(5)
                        .map((f) => Column(children: [
                              Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14)),
                                  child: Icon(_facilityIcon(f),
                                      color: AppColors.primary, size: 20)),
                              const SizedBox(height: 6),
                              Text(f,
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.textGrey)),
                            ]))
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                  const Text('Description',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(hotel.description,
                      style: const TextStyle(
                          color: AppColors.textGrey, height: 1.55)),
                  const Text('Read More',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Photos'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: hotel.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(hotel.photos[i],
                              width: 110,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 110, color: Colors.grey.shade200))),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Location'),
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Icon(Icons.location_on,
                              color: AppColors.primary, size: 36),
                          SizedBox(height: 6),
                          Text('Map Preview (Frontend Only)',
                              style: TextStyle(color: AppColors.textGrey))
                        ])),
                  ),
                  const SizedBox(height: 22),
                  SectionHeader(title: 'Rating & Reviews', onSeeAll: () {}),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text(hotel.rating.toString(),
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            children: List.generate(
                                5,
                                (i) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Row(children: [
                                        Text('${5 - i}',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                                child: LinearProgressIndicator(
                                                    value: [
                                                      0.85,
                                                      0.6,
                                                      0.3,
                                                      0.15,
                                                      0.08
                                                    ][i],
                                                    backgroundColor:
                                                        AppColors.border,
                                                    color: AppColors.star,
                                                    minHeight: 6))),
                                      ]),
                                    )))),
                  ]),
                  const SizedBox(height: 16),
                  ...MockData.reviews.map((r) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18)),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                  backgroundImage: NetworkImage(r.avatar)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Row(children: [
                                      Expanded(
                                          child: Text(r.name,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      Text(r.date,
                                          style: const TextStyle(
                                              color: AppColors.textGrey,
                                              fontSize: 11))
                                    ]),
                                    const SizedBox(height: 4),
                                    Row(
                                        children: List.generate(
                                            5,
                                            (i) => Icon(Icons.star,
                                                size: 14,
                                                color: i < r.rating.round()
                                                    ? AppColors.star
                                                    : Colors.grey.shade300))),
                                    const SizedBox(height: 6),
                                    Text(r.comment,
                                        style: const TextStyle(
                                            color: AppColors.textGrey)),
                                  ])),
                            ]),
                      )),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Row(children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: '\$${hotel.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                  const TextSpan(
                      text: ' /night',
                      style: TextStyle(color: AppColors.textGrey)),
                ])),
              ]),
          const SizedBox(width: 18),
          Expanded(
              child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BookingInfoScreen(hotel: hotel))),
                  child: const Text('Book Now'))),
        ]),
      ),
    );
  }
}

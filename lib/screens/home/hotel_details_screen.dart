import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import '../booking/booking_info_screen.dart';

class HotelDetailsScreen extends StatefulWidget {
  final Hotel hotel;
  const HotelDetailsScreen({super.key, required this.hotel});
  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  late Hotel _hotel = widget.hotel;
  late Future<List<ReviewItem>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = HotelService.fetchReviews(_hotel.id);
  }

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

  Future<void> _toggleFav() async {
    try {
      final nowFav = await HotelService.toggleFavourite(_hotel);
      setState(() => _hotel = _hotel.copyWith(isFavourite: nowFav));
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
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
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(_hotel.image,
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
                          child: Text(_hotel.name,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold))),
                      IconButton(
                          onPressed: _toggleFav,
                          icon: Icon(
                              _hotel.isFavourite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _hotel.isFavourite
                                  ? Colors.red
                                  : AppColors.textGrey)),
                    ],
                  ),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(_hotel.location,
                        style: const TextStyle(color: AppColors.textGrey)),
                    const Spacer(),
                    const Icon(Icons.star, color: AppColors.star, size: 18),
                    const SizedBox(width: 4),
                    Text('${_hotel.rating}  (${_hotel.reviews} reviews)',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 22),
                  const Text('Facilities',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    children: _hotel.facilities
                        .map((f) =>
                            Column(mainAxisSize: MainAxisSize.min, children: [
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
                  Text(_hotel.description,
                      style: const TextStyle(
                          color: AppColors.textGrey, height: 1.55)),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Photos'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _hotel.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(_hotel.photos[i],
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
                    child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          const Icon(Icons.location_on,
                              color: AppColors.primary, size: 36),
                          const SizedBox(height: 6),
                          Text(_hotel.location,
                              style: const TextStyle(color: AppColors.textGrey))
                        ])),
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Rating & Reviews'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text(_hotel.rating.toString(),
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: List.generate(
                            5,
                            (i) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(children: [
                                    Text('${5 - i}',
                                        style: const TextStyle(fontSize: 12)),
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
                                )),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  FutureBuilder<List<ReviewItem>>(
                    future: _reviews,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const LoadingView();
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty)
                        return const Text('Belum ada review untuk hotel ini.',
                            style: TextStyle(color: AppColors.textGrey));
                      return Column(
                        children: reviews
                            .map((r) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                            backgroundImage: r.avatar.isNotEmpty
                                                ? NetworkImage(r.avatar)
                                                : null,
                                            child: r.avatar.isEmpty
                                                ? const Icon(Icons.person,
                                                    size: 18)
                                                : null),
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
                                                                  FontWeight
                                                                      .bold))),
                                                  Text(r.date,
                                                      style: const TextStyle(
                                                          color: AppColors
                                                              .textGrey,
                                                          fontSize: 11))
                                                ]),
                                                const SizedBox(height: 4),
                                                Row(
                                                    children: List.generate(
                                                        5,
                                                        (i) => Icon(Icons.star,
                                                            size: 14,
                                                            color: i <
                                                                    r.rating
                                                                        .round()
                                                                ? AppColors.star
                                                                : Colors.grey
                                                                    .shade300))),
                                                const SizedBox(height: 6),
                                                Text(r.comment,
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .textGrey)),
                                              ]),
                                        ),
                                      ]),
                                ))
                            .toList(),
                      );
                    },
                  ),
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
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: formatRupiah(_hotel.price),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 19)),
              const TextSpan(
                  text: ' /malam', style: TextStyle(color: AppColors.textGrey)),
            ]),
          ),
          const SizedBox(width: 18),
          Expanded(
              child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BookingInfoScreen(hotel: _hotel))),
                  child: const Text('Book Now'))),
        ]),
      ),
    );
  }
}

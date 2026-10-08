import 'package:flutter/material.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import '../booking/booking_info_screen.dart';

class CarDetailsScreen extends StatefulWidget {
  final Car car;
  const CarDetailsScreen({super.key, required this.car});
  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  late Car _car = widget.car;
  late Future<List<ReviewItem>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = CarService.fetchReviews(_car.id);
  }

  IconData _facilityIcon(String f) {
    switch (f) {
      case 'Air Conditioning':
        return Icons.ac_unit;
      case 'Bluetooth Audio':
        return Icons.bluetooth_audio;
      case 'USB Charger':
        return Icons.usb;
      case 'GPS Navigation':
        return Icons.navigation_outlined;
      case 'Child Seat':
        return Icons.child_friendly_outlined;
      case 'Roof Rack':
        return Icons.roofing_outlined;
      case 'Backup Camera':
        return Icons.videocam_outlined;
      case 'Cruise Control':
        return Icons.speed_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  Widget _specChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _toggleFav() async {
    try {
      final nowFav = await CarService.toggleFavourite(_car);
      setState(() => _car = _car.copyWith(isFavourite: nowFav));
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
              background: Image.network(_car.image,
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
                          child: Text(_car.name,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold))),
                      IconButton(
                          onPressed: _toggleFav,
                          icon: Icon(
                              _car.isFavourite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _car.isFavourite
                                  ? Colors.red
                                  : AppColors.textGrey)),
                    ],
                  ),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(_car.location,
                        style: const TextStyle(color: AppColors.textGrey)),
                    const Spacer(),
                    const Icon(Icons.star, color: AppColors.star, size: 18),
                    const SizedBox(width: 4),
                    Text('${_car.rating}  (${_car.reviews} reviews)',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    _specChip(Icons.event_seat_outlined, '${_car.seats} Kursi'),
                    _specChip(Icons.settings_outlined, _car.transmission),
                    _specChip(Icons.local_gas_station_outlined, _car.fuelType),
                    _specChip(Icons.luggage_outlined, '${_car.baggage} Bagasi'),
                    _specChip(Icons.directions_car_outlined, _car.carType),
                  ]),
                  const SizedBox(height: 22),
                  const Text('Features',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    children: _car.features
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
                  Text(_car.description,
                      style: const TextStyle(
                          color: AppColors.textGrey, height: 1.55)),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Photos'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _car.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(_car.photos[i],
                              width: 110,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 110, color: Colors.grey.shade200))),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Lokasi Penjemputan'),
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
                          Text(_car.location,
                              style: const TextStyle(color: AppColors.textGrey))
                        ])),
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(title: 'Rating & Reviews'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text(_car.rating.toString(),
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingView();
                      }
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return const Text('Belum ada review untuk car ini.',
                            style: TextStyle(color: AppColors.textGrey));
                      }
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
                  text: formatRupiah(_car.price),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 19)),
              const TextSpan(
                  text: ' /hari', style: TextStyle(color: AppColors.textGrey)),
            ]),
          ),
          const SizedBox(width: 18),
          Expanded(
              child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BookingInfoScreen(car: _car))),
                  child: const Text('Sewa Sekarang'))),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/common_widgets.dart';
import '../booking/booking_info_screen.dart';

class CarDetailsScreen extends StatefulWidget {
  final Car car;
  final DateTime? initialPickupDate;
  final DateTime? initialReturnDate;
  final int? initialPassengers;
  final int? initialUnits;
  const CarDetailsScreen({
    super.key,
    required this.car,
    this.initialPickupDate,
    this.initialReturnDate,
    this.initialPassengers,
    this.initialUnits,
  });
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

  void _openPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 220,
              child: Center(child: Text('Foto tidak dapat dimuat')),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLocation() async {
    final query = Uri.encodeComponent('${_car.name} ${_car.location}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      showErrorSnackBar(context, tr('det_map_fail'));
    }
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
                    Text('${_car.rating}  ${tr('det_reviews_count', {'n': '${_car.reviews}'})}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    _specChip(Icons.event_seat_outlined, tr('det_seats', {'n': '${_car.seats}'})),
                    _specChip(Icons.settings_outlined, _car.transmission),
                    _specChip(Icons.local_gas_station_outlined, _car.fuelType),
                    _specChip(Icons.luggage_outlined, tr('det_baggage', {'n': '${_car.baggage}'})),
                    _specChip(Icons.directions_car_outlined, _car.carType),
                  ]),
                  const SizedBox(height: 22),
                  Text(tr('det_features'),
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
                  Text(tr('det_desc'),
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_car.description,
                      style: const TextStyle(
                          color: AppColors.textGrey, height: 1.55)),
                  const SizedBox(height: 22),
                  SectionHeader(title: tr('det_photos')),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _car.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => GestureDetector(
                          onTap: () => _openPhoto(_car.photos[i]),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(_car.photos[i],
                                  width: 110,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      width: 110,
                                      color: Colors.grey.shade200)))),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SectionHeader(title: tr('det_pickup')),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _openLocation,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
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
                                style:
                                    const TextStyle(color: AppColors.textGrey)),
                            const SizedBox(height: 6),
                            Text(tr('det_tap_map'),
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600))
                          ])),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SectionHeader(title: tr('det_reviews')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text(_car.rating.toString(),
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(tr('det_dist'),
                          style: const TextStyle(color: AppColors.textGrey)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  FutureBuilder<List<ReviewItem>>(
                    future: _reviews,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingView();
                      }
                      if (snapshot.hasError) {
                        return ErrorView(
                            message: tr('det_reviews_fail'),
                            onRetry: () =>
                                setState(() => _reviews = CarService.fetchReviews(widget.car.id)));
                      }
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return Text(tr('det_no_reviews'),
                            style: TextStyle(color: AppColors.textGrey));
                      }
                      final counts = List<int>.filled(5, 0);
                      for (final review in reviews) {
                        final star = review.rating.round().clamp(1, 5);
                        counts[5 - star]++;
                      }
                      return Column(
                        children: [
                          ...List.generate(
                              5,
                              (i) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
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
                                                  value: reviews.isEmpty
                                                      ? 0
                                                      : counts[i] /
                                                          reviews.length,
                                                  backgroundColor:
                                                      AppColors.border,
                                                  color: AppColors.star,
                                                  minHeight: 6))),
                                      const SizedBox(width: 6),
                                      Text('${counts[i]}',
                                          style:
                                              const TextStyle(fontSize: 12)),
                                    ]),
                                  )),
                          const SizedBox(height: 16),
                          ...reviews
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
                                )),
                        ],
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
                  text: formatMoney(_car.price),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 19)),
              TextSpan(
                  text: ' ${tr('home_per_day')}', style: const TextStyle(color: AppColors.textGrey)),
            ]),
          ),
          const SizedBox(width: 18),
          Expanded(
              child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BookingInfoScreen(
                                car: _car,
                                initialPickupDate: widget.initialPickupDate,
                                initialReturnDate: widget.initialReturnDate,
                                initialPassengers: widget.initialPassengers,
                                initialUnits: widget.initialUnits,
                              ))),
                  child: Text(tr('det_rent')))),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common_widgets.dart';
import 'hotel_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  late Future<List<Hotel>> _future;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _future = HotelService.fetchHotels();
    ProfileService.fetchProfile().then((p) {
      if (mounted) setState(() => _profile = p);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = HotelService.fetchHotels(query: _search.text));
  }

  @override
  Widget build(BuildContext context) {
    final name = (_profile?['full_name'] ?? 'Traveler').toString();
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, $name',
                              style: const TextStyle(
                                  color: AppColors.textGrey, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const Row(children: [
                            Text('Find Hotel Nearby',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Icon(Icons.keyboard_arrow_down, size: 18),
                          ]),
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined)),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14)
                      ]),
                  child: Column(
                    children: [
                      AppTextField(
                          hint: 'Cari hotel atau kota...',
                          icon: Icons.search,
                          controller: _search),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: _infoChip(
                                Icons.calendar_month_outlined,
                                formatDateId(DateTime.now()
                                    .add(const Duration(days: 7))))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _infoChip(
                                Icons.calendar_month_outlined,
                                formatDateId(DateTime.now()
                                    .add(const Duration(days: 10))))),
                      ]),
                      const SizedBox(height: 14),
                      const Row(children: [
                        Expanded(
                            child: _StaticChip(
                                icon: Icons.person_outline, text: '1 Guest')),
                        SizedBox(width: 12),
                        Expanded(
                            child: _StaticChip(
                                icon: Icons.bed_outlined, text: '1 Room')),
                      ]),
                      const SizedBox(height: 18),
                      PrimaryButton(text: 'Find Hotel', onPressed: _reload),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                FutureBuilder<List<Hotel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const LoadingView();
                    if (snapshot.hasError)
                      return ErrorView(
                          message:
                              'Gagal memuat hotel. Pastikan tabel Supabase sudah dibuat (lihat BACKEND_SETUP.md).',
                          onRetry: _reload);
                    final hotels = snapshot.data ?? [];
                    if (hotels.isEmpty)
                      return const ErrorView(
                          message:
                              'Belum ada hotel. Tambahkan data hotel di Supabase.');
                    final popular = hotels.take(3).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Popular Hotel'),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 225,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: popular.length,
                            itemBuilder: (_, i) => HotelCard(
                              hotel: popular[i],
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => HotelDetailsScreen(
                                            hotel: popular[i])));
                                _reload();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const SectionHeader(title: 'Your Offer List'),
                        const SizedBox(height: 14),
                        ...hotels.map((h) => HotelCard(
                              hotel: h,
                              horizontal: true,
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            HotelDetailsScreen(hotel: h)));
                                _reload();
                              },
                            )),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(icon, size: 19, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13)))
      ]),
    );
  }
}

class _StaticChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StaticChip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(icon, size: 19, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13))
      ]),
    );
  }
}

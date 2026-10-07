import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'hotel_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final popular = MockData.hotels.take(3).toList();
    final offers = MockData.hotels.skip(2).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                      radius: 22,
                      backgroundImage:
                          NetworkImage('https://i.pravatar.cc/100?img=12')),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Find Hotel Nearby',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 12)),
                        Row(children: [
                          Text('California, USA',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Icon(Icons.keyboard_arrow_down, size: 18),
                        ]),
                      ],
                    ),
                  ),
                  Stack(children: [
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined)),
                    Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle))),
                  ]),
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
                          color: Colors.black.withOpacity(0.04), blurRadius: 14)
                    ]),
                child: Column(
                  children: [
                    const AppTextField(
                        hint: 'London, England',
                        icon: Icons.location_on_outlined),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Expanded(
                          child: AppTextField(
                              hint: '09/05/25',
                              icon: Icons.calendar_month_outlined)),
                      SizedBox(width: 12),
                      Expanded(
                          child: AppTextField(
                              hint: '12/05/25',
                              icon: Icons.calendar_month_outlined)),
                    ]),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Expanded(
                          child: AppTextField(
                              hint: '1 Guest', icon: Icons.person_outline)),
                      SizedBox(width: 12),
                      Expanded(
                          child: AppTextField(
                              hint: '1 Room', icon: Icons.bed_outlined)),
                    ]),
                    const SizedBox(height: 18),
                    PrimaryButton(text: 'Find Hotel', onPressed: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SectionHeader(title: 'Popular Hotel', onSeeAll: () {}),
              const SizedBox(height: 14),
              SizedBox(
                height: 225,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: popular.length,
                  itemBuilder: (_, i) => HotelCard(
                    hotel: popular[i],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                HotelDetailsScreen(hotel: popular[i]))),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(title: 'Your Offer List', onSeeAll: () {}),
              const SizedBox(height: 14),
              ...offers.map((h) => HotelCard(
                    hotel: h,
                    horizontal: true,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => HotelDetailsScreen(hotel: h))),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

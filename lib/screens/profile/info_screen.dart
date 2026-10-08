import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class InfoScreen extends StatelessWidget {
  final String title;
  final List<({String heading, String body})> sections;

  const InfoScreen({super.key, required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: const BackButton()),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sections[i].heading,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Text(sections[i].body,
                  style: const TextStyle(
                      color: AppColors.textGrey, height: 1.45)),
            ],
          ),
        ),
      ),
    );
  }
}

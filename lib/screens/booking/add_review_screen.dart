import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AddReviewScreen extends StatefulWidget {
  final Hotel hotel;
  const AddReviewScreen({super.key, required this.hotel});
  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  int rating = 5;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Add Review'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          HotelCard(hotel: widget.hotel, horizontal: true),
          const Text('What are your thoughts on',
              style: TextStyle(color: AppColors.textGrey)),
          Text(widget.hotel.name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                5,
                (i) => IconButton(
                      onPressed: () => setState(() => rating = i + 1),
                      icon: Icon(Icons.star,
                          size: 36,
                          color: i < rating
                              ? AppColors.star
                              : Colors.grey.shade300),
                    )),
          ),
          const SizedBox(height: 18),
          const AppTextField(
              hint: 'Add your review here...', label: 'Your Review'),
          const SizedBox(height: 28),
          PrimaryButton(
              text: 'Submit',
              onPressed: () => showSuccessDialog(context,
                  title: 'Review Submitted',
                  message: 'Thank you for your feedback!',
                  onDone: () => Navigator.pop(context))),
        ]),
      ),
    );
  }
}

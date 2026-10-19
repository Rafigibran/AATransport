import 'package:flutter/material.dart';
import '../../models/car.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/common_widgets.dart';

class AddReviewScreen extends StatefulWidget {
  final Car car;
  final String? bookingId;
  const AddReviewScreen({super.key, required this.car, this.bookingId});
  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  int rating = 5;
  final _comment = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await CarService.addReview(
          carId: widget.car.id,
          bookingId: widget.bookingId,
          rating: rating,
          comment: _comment.text);
      if (!mounted) return;
      showSuccessDialog(context,
          title: tr('ar_done_title'),
          message: tr('ar_done_msg'),
          onDone: () => Navigator.pop(context));
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('ar_title')), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CarCard(car: widget.car, horizontal: true),
            Text(tr('ar_sub'),
                style: TextStyle(color: AppColors.textGrey)),
            Text(widget.car.name,
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
            AppTextField(
                hint: tr('ar_hint'),
                label: tr('ar_label'),
                controller: _comment),
            const SizedBox(height: 28),
            PrimaryButton(
                text: _loading ? tr('common_sending') : tr('common_submit'),
                onPressed: _loading ? null : _submit),
          ],
        ),
      ),
    );
  }
}

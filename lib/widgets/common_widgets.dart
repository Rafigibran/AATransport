import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/car.dart';
import '../utils/format.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutline;
  const PrimaryButton(
      {super.key, required this.text, this.onPressed, this.isOutline = false});

  @override
  Widget build(BuildContext context) {
    if (isOutline) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: const BorderSide(color: AppColors.primary),
        ),
        child: Text(text),
      );
    }
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }
}

class AppTextField extends StatelessWidget {
  final String hint;
  final String? label;
  final IconData? icon;
  final bool obscure;
  final TextEditingController? controller;
  final Widget? suffix;
  const AppTextField(
      {super.key,
      required this.hint,
      this.label,
      this.icon,
      this.obscure = false,
      this.controller,
      this.suffix});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textGrey),
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.textGrey, size: 20)
                : null,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onTap;
  final bool horizontal;
  const CarCard(
      {super.key, required this.car, this.onTap, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: horizontal ? null : 220,
        margin: EdgeInsets.only(
            right: horizontal ? 0 : 14, bottom: horizontal ? 14 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: horizontal
            ? Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20)),
                    child: Image.network(car.image,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 110,
                            height: 110,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.directions_car))),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _info(),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(car.image,
                        height: 130,
                        width: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            height: 130,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.directions_car, size: 40))),
                  ),
                  Padding(padding: const EdgeInsets.all(12), child: _info()),
                ],
              ),
      ),
    );
  }

  Widget _info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(car.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
            const Icon(Icons.star, color: AppColors.star, size: 16),
            const SizedBox(width: 4),
            Text(car.rating.toString(),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.location_on_outlined,
              size: 14, color: AppColors.textGrey),
          const SizedBox(width: 4),
          Text(car.location,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: formatRupiah(car.price),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const TextSpan(
                  text: ' /hari',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionHeader({super.key, required this.title, this.onSeeAll});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
        if (onSeeAll != null)
          TextButton(
              onPressed: onSeeAll,
              child: const Text('View All',
                  style: TextStyle(color: AppColors.primary))),
      ],
    );
  }
}

void showSuccessDialog(BuildContext context,
    {required String title,
    required String message,
    String buttonText = 'Done',
    VoidCallback? onDone}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle),
            child: const Icon(Icons.check_circle,
                color: AppColors.primary, size: 42),
          ),
          const SizedBox(height: 18),
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 24),
          PrimaryButton(
              text: buttonText,
              onPressed: () {
                Navigator.pop(context);
                onDone?.call();
              }),
        ],
      ),
    ),
  );
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 44, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                  width: 180,
                  child: PrimaryButton(text: 'Coba Lagi', onPressed: onRetry)),
            ],
          ],
        ),
      ),
    );
  }
}

void showErrorSnackBar(BuildContext context, Object error) {
  final msg = error.toString().replaceFirst('Exception: ', '');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

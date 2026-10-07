import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'reset_password_screen.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verify Your Account!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Enter the OTP code sent to your email.',
                style: TextStyle(color: AppColors.textGrey)),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                  4,
                  (i) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: i == 2
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.4)),
                        child: Center(
                            child: Text(['2', '4', '1', ''][i],
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold))),
                      )),
            ),
            const SizedBox(height: 16),
            const Center(
                child: Text("Don't receive OTP?  Re-send Code",
                    style: TextStyle(color: AppColors.textGrey))),
            const Spacer(),
            // Simple number pad UI (frontend only)
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.9,
              children: [
                '1',
                '2',
                '3',
                '4',
                '5',
                '6',
                '7',
                '8',
                '9',
                '*',
                '0',
                '⌫'
              ]
                  .map((k) => Center(
                      child: Text(k,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600))))
                  .toList(),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
                text: 'Verify',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ResetPasswordScreen()))),
          ],
        ),
      ),
    );
  }
}

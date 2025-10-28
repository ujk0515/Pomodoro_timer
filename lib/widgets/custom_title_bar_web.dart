import 'package:flutter/material.dart';

// 웹용 간단한 타이틀바
class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // App Icon
          Image.asset(
            'assets/timer_icon.png',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 8),
          // App Title
          const Expanded(
            child: Text(
              'Pomodoro Timer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

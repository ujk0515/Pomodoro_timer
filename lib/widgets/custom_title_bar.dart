import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends StatefulWidget {
  const CustomTitleBar({super.key});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isAlwaysOnTop = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkAlwaysOnTop();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _checkAlwaysOnTop() async {
    final isOnTop = await windowManager.isAlwaysOnTop();
    setState(() {
      _isAlwaysOnTop = isOnTop;
    });
  }

  Future<void> _toggleAlwaysOnTop() async {
    final newValue = !_isAlwaysOnTop;
    await windowManager.setAlwaysOnTop(newValue);
    setState(() {
      _isAlwaysOnTop = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        windowManager.startDragging();
      },
      child: Container(
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
            // Always On Top Button
            _buildTitleBarButton(
              icon: _isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
              onPressed: _toggleAlwaysOnTop,
              tooltip: 'Always on Top',
            ),
            // Minimize Button
            _buildTitleBarButton(
              icon: Icons.minimize,
              onPressed: () => windowManager.minimize(),
              tooltip: 'Minimize',
            ),
            // Close Button
            _buildTitleBarButton(
              icon: Icons.close,
              onPressed: () => windowManager.close(),
              tooltip: 'Close',
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isClose = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 46,
          height: 40,
          decoration: BoxDecoration(
            color: isClose ? Colors.transparent : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

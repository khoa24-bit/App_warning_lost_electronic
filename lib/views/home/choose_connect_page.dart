import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChooseConnectPage extends StatelessWidget {
  const ChooseConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Phương thức kết nối',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Center(                                           // ⬅️ căn giữa
              child: Text(
                'CHỌN PHƯƠNG THỨC KẾT NỐI',
                style: TextStyle(
                  color: Color(0xFF3F51B5),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SquareButton(
                    color: theme.colorScheme.primary,
                    icon: Icons.add_box_outlined,
                    text: 'Thiết bị\nmới',
                    onTap: () => context.go('/add-device'),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _SquareButton(
                    color: theme.colorScheme.secondary,
                    icon: Icons.link,
                    text: 'Thiết bị\nđược chia sẻ',
                    outlined: true,
                    onTap: () => context.go('/claim-device'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/*════════════════════════════════════*/
class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.color,
    this.outlined = false,
  });

  final IconData      icon;
  final String        text;
  final VoidCallback  onTap;
  final Color         color;
  final bool          outlined;

  @override
  Widget build(BuildContext context) {
    final btnStyle = OutlinedButton.styleFrom(
      // Viền đen 1 px cho cả hai nút
      side: const BorderSide(color: Colors.black, width: 1),
      backgroundColor:
          outlined ? Colors.transparent : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      foregroundColor: color,
      minimumSize: const Size.square(120),
      padding: const EdgeInsets.all(16),
      elevation: outlined ? 0 : 2,
      shadowColor: Colors.black12,
    );

    return AspectRatio(
      aspectRatio: 1,
      child: OutlinedButton(
        style: btnStyle,
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final String location;

  const MainShell({
    super.key,
    required this.child,
    required this.location,
  });

  int _indexFromLocation(String location) {
    if (location.startsWith('/profile')) return 1;
    return 0; // Home mặc định
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      body: SafeArea(child: child),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/choose-connect'),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.devices),
              color: currentIndex == 0
                  ? Theme.of(context).colorScheme.primary
                  : null,
              onPressed: () => _onNavTap(context, 0),
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: const Icon(Icons.person),
              color: currentIndex == 1
                  ? Theme.of(context).colorScheme.primary
                  : null,
              onPressed: () => _onNavTap(context, 1),
            ),
          ],
        ),
      ),
    );
  }
}

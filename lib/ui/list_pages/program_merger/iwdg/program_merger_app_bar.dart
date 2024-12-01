import 'package:flutter/material.dart';

class ProgramMergerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final VoidCallback onBack;

  const ProgramMergerAppBar({
    super.key,
    required this.isLoading,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Program Oluştur'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack,
      ),
      actions: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.white),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
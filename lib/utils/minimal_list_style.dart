// widgets/minimal_list_tile.dart
import 'package:flutter/material.dart';

class MinimalListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MinimalListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

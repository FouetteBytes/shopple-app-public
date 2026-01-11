import 'package:flutter/material.dart';

/// Debug personalization panel disabled to save cloud costs.
/// Kept as a no-op widget to avoid conditional imports/usages.
class DebugPersonalizationPanel extends StatelessWidget {
  const DebugPersonalizationPanel({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

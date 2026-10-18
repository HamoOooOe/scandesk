import 'package:flutter/material.dart';

/// Brand colors. The theme builds the full color scheme from [seed].
class AppColors {
  const AppColors._();

  static const Color seed = Color(0xFF1F5FA8);

  // Ticket status colors (used by status chips later).
  static const Color statusNew = Color(0xFF6B7280);
  static const Color statusAssigned = Color(0xFF2563EB);
  static const Color statusInProgress = Color(0xFFD97706);
  static const Color statusResolved = Color(0xFF16A34A);

  // Priority colors.
  static const Color priorityLow = Color(0xFF64748B);
  static const Color priorityMedium = Color(0xFFCA8A04);
  static const Color priorityHigh = Color(0xFFDC2626);
}

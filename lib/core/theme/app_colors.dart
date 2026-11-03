import 'package:flutter/material.dart';

/// ScanDesk is drawn like an equipment inspection tag: cool tag-stock
/// white, ink-navy type, one deep teal, and a safety orange that is kept
/// for "open" and "overdue" so it always means something.
class AppColors {
  const AppColors._();

  // Light scheme: tag stock.
  static const Color ink = Color(0xFF0E1A2B);
  static const Color stock = Color(0xFFF1F5F4);
  static const Color teal = Color(0xFF0B6B66);
  static const Color tealContainer = Color(0xFFD3EFEB);

  // Dark scheme: carbon stock.
  static const Color carbon = Color(0xFF0B1317);
  static const Color tealLift = Color(0xFF5ED6C9);

  // Ticket status. Each one is also drawn with its own shape
  // (see StatusTag), so the color is never the only signal.
  static const Color statusOpen = Color(0xFFD9480F);
  static const Color statusAssigned = Color(0xFF2456D6);
  static const Color statusInProgress = Color(0xFFB45309);
  static const Color statusResolved = teal;

  // Priority.
  static const Color priorityLow = Color(0xFF5B6B7B);
  static const Color priorityMedium = Color(0xFFB45309);
  static const Color priorityHigh = Color(0xFFC2260F);

  // Kept for code written in earlier sprints.
  static const Color seed = teal;
  static const Color statusNew = statusOpen;
  static const Color statusAssignedLegacy = statusAssigned;
}

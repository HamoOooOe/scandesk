import 'package:flutter_test/flutter_test.dart';

import 'package:scandesk/features/auth/domain/user_role.dart';

void main() {
  group('UserRole.fromValue', () {
    test('parses every known role', () {
      expect(UserRole.fromValue('employee'), UserRole.employee);
      expect(UserRole.fromValue('technician'), UserRole.technician);
      expect(UserRole.fromValue('manager'), UserRole.manager);
    });

    test('falls back to employee for unknown or null values', () {
      expect(UserRole.fromValue('admin'), UserRole.employee);
      expect(UserRole.fromValue(null), UserRole.employee);
    });
  });

  group('permissions', () {
    test('only managers can manage assets', () {
      expect(UserRole.manager.canManageAssets, isTrue);
      expect(UserRole.technician.canManageAssets, isFalse);
      expect(UserRole.employee.canManageAssets, isFalse);
    });

    test('technicians and managers can work on tickets', () {
      expect(UserRole.technician.canWorkOnTickets, isTrue);
      expect(UserRole.manager.canWorkOnTickets, isTrue);
      expect(UserRole.employee.canWorkOnTickets, isFalse);
    });
  });
}

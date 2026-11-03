import 'package:flutter_test/flutter_test.dart';

import 'package:scandesk/features/qr/domain/qr_payload.dart';

void main() {
  group('QrPayload.encode', () {
    test('wraps the code in a scandesk:// link', () {
      expect(QrPayload.encode('LAP-0007'), 'scandesk://asset/LAP-0007');
    });
  });

  group('QrPayload.parse', () {
    test('reads what encode wrote', () {
      expect(QrPayload.parse(QrPayload.encode('PRT-0012')), 'PRT-0012');
    });

    test('accepts a bare code, any case, with spaces around it', () {
      expect(QrPayload.parse('  lap-0007 '), 'LAP-0007');
    });

    test('accepts codes with more than four digits', () {
      expect(QrPayload.parse('NET-12345'), 'NET-12345');
    });

    test('rejects other apps and other links', () {
      expect(QrPayload.parse('https://example.com/asset/LAP-0007'), isNull);
      expect(QrPayload.parse('scandesk://ticket/LAP-0007'), isNull);
      expect(QrPayload.parse('scandesk://asset/LAP-0007/extra'), isNull);
    });

    test('rejects text that is not a code', () {
      expect(QrPayload.parse(''), isNull);
      expect(QrPayload.parse('hello'), isNull);
      expect(QrPayload.parse('LAP-7'), isNull);
      expect(QrPayload.parse('LAPTOP-0007'), isNull);
    });
  });
}

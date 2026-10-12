import 'package:field_crm/core/result/failure.dart';
import 'package:field_crm/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Ok maps and folds', () {
      const r = Ok<int, Failure>(2);
      expect(r.isOk, isTrue);
      expect(r.map((v) => v * 2).valueOrNull, 4);
      expect(r.fold((v) => 'ok$v', (f) => 'err'), 'ok2');
      expect(r.getOrThrow(), 2);
    });

    test('Err keeps failure through map and throws on getOrThrow', () {
      const r = Err<int, Failure>(Failure.network());
      expect(r.isErr, isTrue);
      expect(r.map((v) => v * 2).errorOrNull, const Failure.network());
      expect(r.getOrThrow, throwsStateError);
    });

    test('orThrow throws the Failure itself', () async {
      final f = Future.value(
        const Err<int, Failure>(Failure.validation('bad', field: 'x')),
      );
      await expectLater(
        f.orThrow,
        throwsA(isA<ValidationFailure>().having((v) => v.field, 'field', 'x')),
      );
    });
  });

  group('Failure.isTransient', () {
    test('only network and timeout may be queued', () {
      expect(const Failure.network().isTransient, isTrue);
      expect(const Failure.timeout().isTransient, isTrue);
      expect(const Failure.validation('x').isTransient, isFalse);
      expect(const Failure.permissionDenied().isTransient, isFalse);
      expect(const Failure.conflict().isTransient, isFalse);
      expect(const Failure.unknown().isTransient, isFalse);
    });
  });
}

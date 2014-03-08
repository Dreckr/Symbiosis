library dado.test.scope.singleton;

import 'package:dado/dado.dart';
import 'package:unittest/unittest.dart';

void testSingletonScope() {
  group('SingletonScope:', () {
    var scope;

    test('Instantiation:', () {
      scope = new SingletonScope();

      expect(scope.instancePool, isEmpty);
      expect(scope.isInProgress, isTrue);
    });
  });
}
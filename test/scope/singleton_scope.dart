library symbiosis.test.scope.singleton;

import 'package:symbiosis/symbiosis.dart';
import 'package:unittest/unittest.dart';
import '../common.dart';

void testSingletonScope() {
  group("SingletonScope:", () {
    var scope;

    setUp(() {
      scope = new SingletonScope();
    });

    test("Instantiation:", () {
      expect(scope.instancePool, isEmpty);
      expect(scope.isInProgress, isTrue);
    });

    test("Instance stored", () {
      var instance = new Foo("foo");
      var key = new Key(Foo);
      scope.storeInstance(key, instance);

      expect(scope.instancePool, hasLength(1));
      expect(scope.getInstanceOf(key), equals(instance));
    });
  });
}
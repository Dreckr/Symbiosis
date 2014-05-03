library symbiosis.test.module.declarative;

import 'package:dado/symbiosis.dart';
import 'package:unittest/unittest.dart';
import '../common.dart';

void testDeclarativeModule() {
  group("Declarative Module:", () {
    var module = new TestDeclarativeModule();
    var bindings = module.bindings;
    var scopes = module.scopes;

    test("Bindings registered", () {
      void expectBindingRegistered (Key key,
                                        Matcher typeMatcher,
                                        [Type scope = null]) {
        var binding = findBinding(key, bindings);

        expect(binding, isNotNull);
        expect(binding, typeMatcher);
        expect(binding.scope, equals(scope));
      }

      expectBindingRegistered(
                            new Key(Foo),
                            new isInstanceOf<InstanceBinding>());

      expectBindingRegistered(
                            new Key(Bar, annotatedWith: B),
                            new isInstanceOf<ConstructorBinding>());

      expectBindingRegistered(
                            new Key(Baz),
                            new isInstanceOf<ConstructorBinding>());

      expectBindingRegistered(
                            new Key(Provided),
                            new isInstanceOf<ProviderBinding>());

      expectBindingRegistered(
                            new Key(Qux),
                            new isInstanceOf<ConstructorBinding>(),
                            SingletonScope);

      expect(bindings, hasLength(5));
    });

    test("Scopes registered", () {
      expect(scopes, hasLength(1));
      expect(scopes[0], new isInstanceOf<TestScope>());
      expect(scopes[0], equals(module.testScope));
    });

  });
}

class TestDeclarativeModule extends DeclarativeModule {

  Scope testScope = new TestScope();

  var dynamic = "";

  Foo foo = new Foo("test");

  @B
  Bar bar;

  Baz baz;

  Provided provided(Foo foo) => new Provided(1, foo);

  @Singleton
  Qux qux;

}
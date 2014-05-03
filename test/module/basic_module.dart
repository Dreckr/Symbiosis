library symbiosis.test.module.basic;

import 'package:dado/symbiosis.dart';
import 'package:unittest/unittest.dart';
import '../common.dart';

void testBasicModule() {

  group("Binding Builder:", () {
    var bindingBuilder;
    var binding;

    test("Builds instance binding", () {
      bindingBuilder = new BindingBuilder(Foo)..instance = new Foo("foo");
      binding = bindingBuilder.build();

      expect(binding, new isInstanceOf<InstanceBinding>());
      expect(binding.key, equals(new Key(Foo)));
      expect(binding.scope, isNull);

      bindingBuilder.scope = SingletonScope;
      binding = bindingBuilder.build();

      expect(binding, new isInstanceOf<InstanceBinding>());
      expect(binding.key, equals(new Key(Foo)));
      expect(binding.scope, isNull);
    });

    test("Builds constructor binding", () {
      bindingBuilder = new BindingBuilder(Foo);
      binding = bindingBuilder.build();

      expect(binding, new isInstanceOf<ConstructorBinding>());
      expect(binding.key, equals(new Key(Foo)));
      expect(binding.scope, isNull);

      bindingBuilder.scope = SingletonScope;
      binding = bindingBuilder.build();

      expect(binding, new isInstanceOf<ConstructorBinding>());
      expect(binding.key, equals(new Key(Foo)));
      expect(binding.scope, equals(SingletonScope));
    });

    test("Builds provider binding", () {
      bindingBuilder = new BindingBuilder(Foo)
      ..provider = () => new Foo("foo");
      binding = bindingBuilder.build();

      expect(binding, new isInstanceOf<ProviderBinding>());
      expect(binding.key, equals(new Key(Foo)));
      expect(binding.scope, isNull);

      bindingBuilder.scope = SingletonScope;
      binding = bindingBuilder.build();

      expect(binding, new isInstanceOf<ProviderBinding>());
      expect(binding.key, equals(new Key(Foo)));
      expect(binding.scope, equals(SingletonScope));
    });

    test("Builds rebinding", () {
      bindingBuilder = new BindingBuilder(Baz)..to = SubBaz;
      binding = bindingBuilder.build();

      expect(binding, new isInstanceOf<Rebinding>());
      expect(binding.key, equals(new Key(Baz)));
      expect(binding.scope, isNull);

      bindingBuilder.scope = SingletonScope;
      binding = bindingBuilder.build();

      expect(binding, new isInstanceOf<Rebinding>());
      expect(binding.key, equals(new Key(Baz)));
      expect(binding.scope, equals(SingletonScope));
    });
  });

  group("Basic Module:", () {
    var basicModule = new TestBasicModule();
    var bindings = basicModule.bindings;
    var scopes = basicModule.scopes;

    test("Bindings registered", () {
      expect(findBinding(new Key(Foo), bindings), isNotNull);
      expect(findBinding(new Key(Bar, annotatedWith: B), bindings), isNotNull);
      expect(findBinding(new Key(Baz), bindings), isNotNull);
      expect(findBinding(new Key(Qux), bindings), isNotNull);
      expect(findBinding(new Key(Provided), bindings), isNotNull);
      expect(bindings, hasLength(5));
    });

    test("Scopes registered", () {
      expect(scopes, hasLength(1));
      expect(scopes[0], new isInstanceOf<TestScope>());
    });
  });

}

class TestBasicModule extends BasicModule {

  @override
  configure() {
    registerScope(new TestScope());

    bind(Foo);
    bind(Bar, B);
    bind(Baz).to = SubBaz;
    bind(Qux).instance = new Qux();
    bind(Provided).provider = (Foo foo) {
      new Provided(0, foo);
    };
  }

}
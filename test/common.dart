library symbiosis.test.common;

import 'package:symbiosis/symbiosis.dart';

Binding findBinding (Key key, List<Binding> bindings) =>
    bindings
      .firstWhere(
          (binding) => binding.key == key,
          orElse: () => null);

const A = const Named('a');
const B = const Named('b');

class TestScope extends Scope {

  Map<Key, Object> _instancePool = new Map();

  @override
  Map<Key, Object> get instancePool => _instancePool;

  @override
  bool get isInProgress => true;

  @override
  void storeInstance(Key key, Object instance) {
    _instancePool[key] = instance;
  }

  @override
  bool containsInstanceOf(Key key) =>
      _instancePool.containsKey(key);

  @override
  Object getInstanceOf(Key key) =>
      _instancePool[key];
}

// object with a dependency bound to an instance
class Foo {
  String name;

  Foo(String this.name);

  String toString() => "Foo { name: $name}";
}

// object with a singleton dependecy
class Bar {
  Foo foo;

  Bar(Foo this.foo);

  String toString() => "Bar {foo: $foo}";
}

// subclass of dependency for binding
class SubBar extends Bar {
  SubBar(Foo foo) : super(foo);
}

// object with an unscoped (non-singleton) dependency
class Baz {
  Bar bar;

  Baz(Bar this.bar);
}

class SubBaz extends Baz {
  SubBaz(Bar bar) : super(bar);
}

class Qux {
}

// object with a cyclic, unscoped dependency
class Cycle {
  Cycle(Cycle c);
}

// object that depends on the module
class NeedsInjector {
  Injector injector;

  NeedsInjector(Injector this.injector);
}

// a class that's not injectable, and so needs a provider function
class Provided {
  final int i;

  Provided(int this.i, Foo foo);
}

class HasAnnotatedConstructor {
  String a;

  HasAnnotatedConstructor();

  @inject
  HasAnnotatedConstructor.annotated(String this.a);
}

class HasNoArgsConstructor {
  String a;

  HasNoArgsConstructor(String this.a);

  HasNoArgsConstructor.noArgs();
}

class HasSatisfiedNamedParameter {
  String a;

  HasSatisfiedNamedParameter({String this.a});
}

class HasUnsatisfiedNamedParameter {
  double a;

  HasUnsatisfiedNamedParameter({double this.a});
}

class HasMultipleUnannotatedConstructors {
  double a, b;

  HasMultipleUnannotatedConstructors.one(this.a);
  HasMultipleUnannotatedConstructors.two(this.b);
}

// Indirect circular dependency tests classes
class Quux {
  Corge corge;

  Quux(Corge this.corge);
}

class Corge {
  Grault grault;

  Corge(Grault this.grault);
}

class Grault {
  Corge corge;

  Grault(Corge this.corge);
}

typedef int SomeFunctionType(String someArg);

class Module1 extends BasicModule {

  @override
  configure() {
    bind(String).instance = "a";
    bind(String, B).instance = "b";

    bind(Foo).scope = SingletonScope;
    bind(Foo, B).scope = SingletonScope;

    bind(Bar);

    bind(NeedsInjector);
    bind(HasSatisfiedNamedParameter);
    bind(HasUnsatisfiedNamedParameter);

    bind(SomeFunctionType).instance = (String someArg) => 0;
  }
}

class Module2 extends BasicModule {

  @override
  configure() {
    bind(Foo).instance = new Foo("foo2");
    bind(SubBar);
  }
}

class Module3 extends BasicModule {

  @override
  configure() {
    bind(Qux).scope = SingletonScope;
    bind(SubBar);
    bind(Bar).provider = (SubBar subBar) => subBar;
  }
}

class Module4 extends BasicModule {

  @override
  configure() {
    bind(Cycle);
  }
}

class Module5 extends BasicModule {
  Quux newQuux;

  Corge newCorge;

  Grault newGrault;

  @override
  configure() {
    bind(Quux);
    bind(Corge);
    bind(Grault);
  }
}
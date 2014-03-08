library dado.test.common;

import 'package:dado/dado.dart';

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
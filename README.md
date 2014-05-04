Symbiosis
=========
[![Build Status](https://drone.io/github.com/Dreckr/Symbiosis/status.png)](https://drone.io/github.com/Dreckr/Symbiosis/latest)

Symbiosis is a dependency injection framework with heavy focus on extensibility.

It provides a solid core, a DI interface and a set of tools that let you
get started right away.

Using Symbiosis is simple and straight forward:

```dart
import 'package:symbiosis/symbiosis.dart';

// Dependant, needs an instance of Bar to be constructed.
class Foo {
  Bar bar;
  
  Foo(this.bar);
}

// Dependency, needs to be constructed to fulfill Foo's constructor.
class Bar {

  Bar();
}

// Your custom module, defining bindings for classes that are available for 
// injection.
class MyModule extends BasicModule {
  
  configure() {
    bind(Foo);
    bind(Bar);
  }
}

// Create an injector, passing your module and ask it for instances.
void main() {
  var injector = new Injector([new MyModule()]);
  var instance = injector.getInstanceOf(Foo);
}
```

Installation
------------

Use [Pub][pub] and simply add the following to your `pubspec.yaml` file:

```
dependencies:
  symbiosis: 0.6.0
```

Declaring bindings
------------------

Out of the box, there are 2 types of modules that let declare bindings, 
basic modules and declarative modules.

Basic modules are inspired on Java Guice's modules and are really easy to use:

```dart
import 'package:symbiosis/symbiosis.dart';

class MyBasicModule extends BasicModule {
  
  configure() {
    // Defines a constructor binding for a type
    bind(Foo);
    
    // Binds a type to an implementation
    bind(Baz).to = SubBaz;

    // Binds a type to an instance
    bind(Qux).instance = new Qux();
    
    // Defines an alternative binding for type Foo by passing a 
    // BindingAnnotation
    bind(Foo, const Named("b")).instance = new Foo.b();
    
    // Binds a provider function to a type
    bind(Provided).provider = (Foo foo) {
      new Provided(foo);
    };
    
    // Defines a scoped constructor binding
    // Any type of binding can be scoped by defining its 'scope' property.
    bind(Scoped).scope = SingletonScope;
  }
}
```

Declaratives modules are inspired on Dart Dado's modules and are a bit more fun:

```dart
import 'package:symbiosis/symbiosis.dart';

class MyDeclarativeModule extends DeclarativeModule {

  // Defines a constructor binding for a type
  Foo foo;
  
  // Binds a type to an instance
  Qux qux = new Qux();

  // Defines an alternative binding for type Foo by passing annotating it with
  // a BindingAnnotation
  @Named("b")
  Foo alteranativeFoo = new Foo.b();

  // Binds a provider function to a type
  Provided provided(Foo foo) => new Provided(foo);

  // Defines a scoped constructor binding
  // Any type of binding can be scoped by annotating it with a ScopeAnnotation.
  @Singleton
  Scoped scope;
}
```

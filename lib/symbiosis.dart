/**
 * Symbiosis is a fully-featured dependency injection framework with heavy focus
 * on extensibility.
 *
 * To understand how Symbiosis works, you must understand this 5 simple concepts
 * and how they interact:
 *  * [Binding] - Define how an instance of a [Type] is obtained;
 *  * [Key] - Identify different bindings;
 *  * [Scope] - Defines the lifetime of instances;
 *  * [Module] - Is a set of bindings and scopes that configure an [Injector];
 *  * [Injector] - Builds instances according to its configuration (modules).
 *
 *  Symbiosis has a hard implementation for only 2 of this concepts, [Key]
 *  and [Injector], the others are interfaces that you can implement yourself,
 *  if desired, or you can use one of the built-in implementations.
 *
 *  To use Symbiosis is really simple. First, you need to create a [Module]:
 *    class MyModule extends BasicModule {
 *
 *        void configure() {
 *          bind(MyType);
 *        }
 *    }
 *
 *  Your module can implement the [Module] interface directly or it can extend
 *  or it can extend one of the built-in abstract classes
 *  ([BasicModule] and [DeclarativeModule]). Now, you only have to create an
 *  injector passing your module (or many of them) and ask it for instances:
 *
 *    void main() {
 *      var injector = new Injector([new MyModule]);
 *      MyType myInstance = injector.getInstanceOf(MyType);
 *    }
 */

library symbiosis;

export 'src/basic_module.dart';
export 'src/binding.dart';
export 'src/declarative.dart';
export 'src/injector.dart';
export 'src/key.dart';
export 'src/mirror_bindings.dart';
export 'src/module.dart';
export 'src/scanner.dart';
export 'src/scope.dart';
export 'package:inject/inject.dart' show BindingAnnotation, inject;

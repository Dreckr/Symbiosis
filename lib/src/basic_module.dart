library symbiosis.module.basic;

import 'dart:collection';
import 'package:inject/inject.dart';
import 'binding.dart';
import 'key.dart';
import 'mirror_bindings.dart';
import 'module.dart';
import 'scope.dart';

/**
 * A basic implementation of [Module].
 *
 * To use this class you must create your own [Module] extending [BasicModule]
 * and implement the [configure] method. You can register bindings and scopes
 * using [bind] and [registerScope], respectively.
 *
 * Example
 * -------
 *
 * class MyModule extends BasicModule {
 *
 *   configure() {
 *     // Register a new scope
 *     registerScope(new MyScope());
 *
 *     // Creates a constructor binding for MyType.
 *     bind(MyType);
 *
 *     // Creates a constructor binding for MyAnnotatedType
 *     // with a binding annotation.
 *     bind(MyAnnotatedType, const MyAnnotation());
 *
 *     // Creates a constructor binding for MyImplementation
 *     // and a binding that uses instances of MyImplementation
 *     // to fulfill MyInterface dependencies.
 *     bind(MyImplementation);
 *     bind(MyInterface).to = MyImplementation;
 *
 *     // Creates a binding that executes a function to
 *     // build instances of MyProvidedType.
 *     bind(MyProvidedType).provider = myProviderFunction;
 *
 *     // Creates a binding that executes a function to
 *     // build instances of MyScopedProvidedType and
 *     // stores them in MyScope.
 *     bind(MyScopedProvidedType)
 *       ..provider = myProviderFunction
 *       ..scope = MyScope;
 *   }
 * }
 */
abstract class BasicModule implements Module {
  List<Binding> _bindings = new List();
  List<Scope> _scopes = new List();

  @override
  List<Binding> get bindings => new UnmodifiableListView(_bindings);

  @override
  List<Scope> get scopes => new UnmodifiableListView(_scopes);

  List<BindingBuilder> _bindingBuilders = new List();

  BasicModule() {
    configure();
    _bindingBuilders.forEach((bindingBuilder) {
      var binding = bindingBuilder.build();
      _bindings.add(binding);
    });
  }

  @override
  void install(Module module) {
    _scopes.addAll(module.scopes);
    _bindings.addAll(module.bindings);
  }

  /**
   * Registers a new binding for [type]. [annotation] defines if this is an
   * alternative binding for this [type].
   *
   * This method returns a [BindingBuilder] that can be modified to alter your
   * the registered binding.
   */
  BindingBuilder bind(Type type, [BindingAnnotation annotation]) {
    var bindingBuilder = new BindingBuilder(type, annotation);
    _bindingBuilders.add(bindingBuilder);
    return bindingBuilder;
  }

  /// Registers a [Scope] on this module.
  void registerScope(Scope scope) {
    _scopes.add(scope);
  }

  /// Configures this module.
  configure();
}


/// A configurable builder of bindings
class BindingBuilder {
  /// The type to be binded
  final Type type;

  /// The annotation of [type]
  final BindingAnnotation annotation;

  /// If set, builds an [InstanceBinding]
  Object instance;

  /// If set, builds a binding that links [type] to [to]
  Type to;

  /// The annotation of [to]
  BindingAnnotation toAnnotation;

  /// If set, build a [ProviderBinding]
  Function provider;

  /// Defines the scope of the binding
  Type scope;

  BindingBuilder(this.type, [this.annotation]);

  /// Returns a binding according to the current state of this object
  Binding build() {
    var key = new Key(type, annotatedWith: annotation);
    var binding;
    if (instance != null) {
      binding = new InstanceBinding(key, instance);
    } else if (provider != null) {
      binding = new ProviderBinding(key, provider, scope: scope);
    } else if (to != null) {
      binding = new Rebinding(key,
          new Key(to, annotatedWith: toAnnotation), scope: scope);
    } else {
      binding = new ConstructorBinding(key, type, scope: scope);
    }

    return binding;
  }

}
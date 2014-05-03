// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dado.module;

import 'dart:collection';
import 'package:inject/inject.dart';
import 'binding.dart';
import 'key.dart';
import 'scope.dart';

/**
 * A Module is a declaration of bindings that instruct an [Injector] how to
 * create objects.
 *
 * This abstract class defines the interface that must be implemented by any
 * module.
 */
abstract class Module {
  /// Bindings declared by this module.
  List<Binding> get bindings;

  /// Scopes provided by this module.
  List<Scope> get scopes;

  /// Installs a module into this. All bindings and scopes provided by [module]
  /// should also be provided by this.
  void install(Module module);
}

// TODO(diego): Test BasicModule
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
 *     bind(MyProvidedType).provider = myProvider;
 *
 *     // Creates a binding that executes a function to
 *     // build instances of MyScopedProvidedType and
 *     // stores them in MyScope.
 *     bind(MyScopedProvidedType)
 *       ..provider = myProvider
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

// TODO(diego): Test BindingBuilder
class BindingBuilder {
  final Type type;
  final BindingAnnotation annotation;

  Object instance;
  Type to;
  BindingAnnotation toAnnotation;
  Function provider;
  Type scope;

  BindingBuilder(this.type, [this.annotation]);

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
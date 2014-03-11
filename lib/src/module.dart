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
  List<Binding> get bindings;
  List<Scope> get scopes;

  void install(Module module);
}

// TODO(diego): Test BaseModule
abstract class BaseModule implements Module {
  List<Binding> _bindings = new List();
  List<Scope> _scopes = new List();

  @override
  List<Binding> get bindings => new UnmodifiableListView(_bindings);

  List<Scope> get scopes => new UnmodifiableListView(_scopes);

  List<BindingBuilder> _bindingBuilders = new List();

  BaseModule() {
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

  BindingBuilder bind(Type type, [BindingAnnotation annotation]) {
    var bindingBuilder = new BindingBuilder(type, annotation);
    _bindingBuilders.add(bindingBuilder);
    return bindingBuilder;
  }

  void registerScope(Scope scope) {
    _scopes.add(scope);
  }

  configure();
}

// TODO(diego): Test BindingBuilder
class BindingBuilder {
  final Type type;
  final BindingAnnotation annotation;

  Object instance;
  Type rebinding;
  BindingAnnotation rebindingAnnotation;
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
    } else if (rebinding != null) {
      binding = new Rebinding(key,
          new Key(rebinding, annotatedWith: rebindingAnnotation), scope: scope);
    } else {
      binding = new ConstructorBinding(key, type, scope: scope);
    }

    return binding;
  }

}
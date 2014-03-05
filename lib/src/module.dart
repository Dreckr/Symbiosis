// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dado.module;

import 'package:inject/inject.dart';
import 'binding.dart';
import 'key.dart';

/**
 * A Module is a declaration of bindings that instruct an [Injector] how to
 * create objects.
 *
 * This abstract class defines the interface that must be implemented by any
 * module.
 */
abstract class Module {
  Map<Key, Binding> get bindings;
  
  void install(Module module);
}


abstract class BaseModule implements Module {
  Map<Key, Binding> _bindings = new Map<Key, Binding>();
  
  @override
  Map<Key, Binding> get bindings {
    if (_bindings.isEmpty) {
      configure();
      _bindingBuilders.forEach((bindingBuilder) {
        var binding = bindingBuilder.build();
        _bindings[binding.key] = binding;
      });
    }
    
    return _bindings;
  }
  
  List<BindingBuilder> _bindingBuilders = new List();

  @override
  void install(Module module) {
    _bindings.addAll(module.bindings);
  }
  
  BindingBuilder bind(Type type, [BindingAnnotation annotation]) {
    var bindingBuilder = new BindingBuilder(type, annotation);
    _bindingBuilders.add(bindingBuilder);
    return bindingBuilder;
  }
  
  configure();
}

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
      binding = new RebindBinding(key, 
          new Key(rebinding, annotatedWith: rebindingAnnotation), scope: scope);
    } else {
      binding = new ConstructorBinding(key, type, scope: scope);
    }
    
    return binding;
  }
  
}
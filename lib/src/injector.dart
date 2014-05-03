// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dado.injector;

import 'dart:collection';
import 'binding.dart';
import 'key.dart';
import 'module.dart';
import 'scope.dart';

/**
 * An Injector constructs objects based on its configuration. The Injector
 * tracks dependencies between objects and uses the bindings defined in its
 * modules and parent injector to resolve the dependencies and inject them into
 * newly created objects.
 *
 * Injectors are rarely used directly, usually only at the initialization of an
 * application to create the root objects for the application. The Injector does
 * most of it's work behind the scenes, creating objects as neccessary to
 * fullfill dependencies.
 *
 * Injectors are hierarchical. [createChild] is used to create injectors that
 * inherit their configuration from their parent while adding or overriding
 * some bindings.
 *
 * An Injector contains a default binding for itself, so that it can be used
 * to request instances generically, or to create child injectors. Applications
 * should generally have very little injector aware code.
 *
 */
class Injector {
  // The key that indentifies the default Injector binding.
  static final Key key =
      new Key(Injector);

  /// The parent of this injector, if it's a child, or null.
  final Injector parent;

  /// The name of this injector, if one was provided.
  final String name;

  final Map<Key, Binding> _bindings = new Map<Key, Binding>();

  final Map<Type, Scope> _scopes = new Map();

  /// A unmodifiable list of all bindings registered in this injector.
  List<Binding> get bindings {
    var bindings = [];

    bindings.addAll(_bindings.values);
    if (parent != null) {
      bindings.addAll(parent.bindings);
    }

    return bindings;
  }

/// A unmodifiable list of all scopes registered in this injector.
  List<Scope> get scopes => new UnmodifiableListView(_scopes.values);
  /**
   * Constructs a new Injector using [modules] to provide bindings. If [parent]
   * is specificed, the injector is a child injector that inherits bindings
   * from its parent. The modules of a child injector add to or override its
   * parent's bindings. [sharedScopes] is a list of types of scope that this
   * child should share with its parent.
   */
  Injector(List<Module> modules,
          {Injector this.parent,
           List<Type> sharedScopes,
           String this.name}) {

    registerBinding(new InstanceBinding(key, this));

    var singletonScope = new SingletonScope();
    registerScope(singletonScope);
    registerBinding(new InstanceBinding(new Key(SingletonScope),
                                        singletonScope));

    if (parent != null && sharedScopes != null) {
      parent._scopes.forEach((type, scope) {
        if (sharedScopes.contains(type)) {
          registerScope(scope);
        }
      });
    }

    modules.forEach(_installModuleScopes);
    modules.forEach(_installModuleBindings);

    _bindings.values.forEach((binding) => _verifyCircularDependency(binding));

  }

  /**
   * Creates a child of this Injector with the additional modules installed.
   * [modules] must be a list of [Module]s that will provide more bindings to
   * the new child injector.
   * [sharedScopes] is a list of types of scope that the new child injector
   * should share with its parent.
   */
  Injector createChild(List<Module> modules, {List<Type> sharedScopes}) =>
      new Injector(modules, parent: this, sharedScopes: sharedScopes);

  /// Registers a new [Scope].
  void registerScope(Scope scope) {
    _scopes[scope.runtimeType] = scope;
  }

  /// Registers a new [Binding].
  void registerBinding(Binding binding) {
    _bindings[binding.key] = _scopeBinding(binding);
  }

  /**
   * Returns an instance of [type]. If [annotatedWith] is provided, returns an
   * instance that was bound with the annotation.
   */
  Object getInstanceOf(Type type, {Object annotatedWith}) {
    var key = new Key(type, annotatedWith: annotatedWith);

    return getInstanceOfKey(key);
  }

  /// Returns an instance for [key].
  Object getInstanceOfKey(Key key) => getInstanceOfBinding(_getBinding(key));


  Object getInstanceOfBinding(Binding binding) {
    var dependencyResolution = _resolveDependencies(binding.dependencies);
    return binding.buildInstance(dependencyResolution);
  }

  Binding _getBinding(Key key) {
    var binding = _findBinding(key);

    if (binding == null) {
      key = new Key(key.type,
                    annotatedWith: key.annotation);

      binding = _findBinding(key);
    }

    if (binding == null) {
      throw new ArgumentError('$key has no binding.');
    }

    return binding;
  }

  Binding _findBinding(Key key) {
    return _bindings.containsKey(key)
        ? _bindings[key]
        : (parent != null)
            ? parent._getBinding(key)
            : null;
  }

  bool containsBindingOf(Key key) => _bindings.containsKey(key) ||
      (parent != null ? parent.containsBindingOf(key) : false);

  DependencyResolution _resolveDependencies(List<Dependency> dependencies) {
      var dependencyResolution = new DependencyResolution();

      dependencies.forEach((dependency) {
          if (!dependency.isNullable || containsBindingOf(dependency.key)) {
            dependencyResolution[dependency] =
                getInstanceOfKey(dependency.key);
          }
      });

      return dependencyResolution;
  }

  void _installModuleScopes(Module module) =>
      module.scopes.forEach(registerScope);

  void _installModuleBindings(Module module) =>
      module.bindings.forEach(registerBinding);

  Binding _scopeBinding(Binding binding) {
    if (binding.scope != null) {
      if (_scopes.containsKey(binding.scope)) {
        binding = new ScopedBinding(_scopes[binding.scope], binding);
      } else {
        throw new ArgumentError("${binding.scope} is not a registered scope");
      }
    }

    return binding;
  }

  void _verifyCircularDependency(Binding binding,
                                  {List<Key> dependencyStack}) {
    if (dependencyStack == null) {
      dependencyStack = [];
    }

    if (dependencyStack.contains(binding.key)) {
      dependencyStack.add(binding.key);
      var stackInfo = dependencyStack.fold(null, (value, dependency) {
        if (value == null) {
          return dependency.toString();
        } else {
          return '$value =>\n$dependency';
        }
      });
      throw new ArgumentError(
          'Circular dependency found on type ${binding.key.type}:\n$stackInfo');
    }

    dependencyStack.add(binding.key);

    var dependencies = binding.dependencies;
    dependencies.forEach((dependency) {
      if (!dependency.isNullable || containsBindingOf(dependency.key)) {
        var dependencyBinding = this._getBinding(dependency.key);

        _verifyCircularDependency(dependencyBinding,
          dependencyStack: dependencyStack);
      }
    });

    dependencyStack.removeLast();
  }

  String toString() => 'Injector: $name';
}

class _ParameterResolution {
  List<Object> positionalParameters;
  Map<Symbol, Object> namedParameters;

  _ParameterResolution (this.positionalParameters, this.namedParameters);

}

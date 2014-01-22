// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dado.injector;

import 'dart:collection';
import 'dart:mirrors';
import 'binding.dart';
import 'key.dart';
import 'module.dart';
import 'scope.dart';
import 'utils.dart' as Utils;

/**
 * An Injector constructs objects based on it's configuration. The Injector
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

  // The map of bindings and its keys.
  final Map<Key, Binding> _bindings = new Map<Key, Binding>();
  
  final Map<Type, Scope> _scopes = new Map<Type, Scope>();
  
  /// A unmodifiable list of all bindings of this injector;
  List<Binding> get bindings {
    var bindings = [];
    
    bindings.addAll(_bindings.values);
    if (parent != null) {
      bindings.addAll(parent.bindings);
    }
    
    return bindings;
  }
  
  List<Scope> get scopes {
    var scopes = [];
    
    scopes.addAll(_scopes.values);
    if (parent != null) {
      scopes.addAll(parent.scopes);
    }
    
    return scopes;
  }

  /**
   * Constructs a new Injector using [modules] to provide bindings. If [parent]
   * is specificed, the injector is a child injector that inherits bindings
   * from its parent. The modules of a child injector add to or override its
   * parent's bindings. [newInstances] is a list of types that a child injector
   * should create distinct instances for, separate from it's parent.
   * newInstances only apply to singleton bindings.
   */
  Injector(List<Module> modules, 
          {Injector this.parent, 
           List<Type> sharedScopes,
           String this.name}) {
    
    _bindings[key] = new _InjectorBinding(this);

    modules.forEach(_registerBindings);

    _bindings.values.forEach((binding) => _verifyCircularDependency(binding));
    
    if (parent != null && sharedScopes != null) {
      parent._scopes.forEach((type, scope) {
        if (sharedScopes.contains(type)) {
          registerScope(scope);
        }
      });
    }
    
    if (!_scopes.containsKey(SingletonScope)) {
      registerScope(new SingletonScope());
    }
  }

  /**
   * Creates a child of this Injector with the additional modules installed.
   * [modules] must be a list of Types that extend Module.
   * [newInstances] is a list of Types that the child should create new
   * instances for, rather than use an instance from the parent.
   */
  Injector createChild(List<Module> modules, {List<Type> newInstances}) =>
      new Injector(modules, parent: this);
  
  void registerScope(Scope scope) {
    _scopes[scope.runtimeType] = scope;
  }

  /**
   * Returns an instance of [type]. If [annotatedWith] is provided, returns an
   * instance that was bound with the annotation.
   */
  Object getInstanceOf(Type type, {Object annotatedWith}) {
    var key = new Key(type, annotatedWith: annotatedWith);

    return getInstanceOfKey(key);
  }

  Object getInstanceOfKey(Key key) {
    var binding = _getBinding(key);
    
    var instance;
    Scope scope;
    
    if (binding.scope != null) {
      if (!_scopes.containsKey(binding.scope)) {
        throw new ArgumentError("${binding.scope} is not a registered scope");
      }
      
      scope = _scopes[binding.scope];
    }
    
    if (scope != null) {
      if (!scope.isInProgress) {
        throw new ArgumentError("${binding.scope} is not in progress");
      }
      
      if (scope.instancePool.containsKey(key)) {
        instance = scope.instancePool[key];
      }
    }
    
    if (instance == null) {
      instance = _buildInstanceOf(binding);
      
      if (scope != null) {
        scope.storeInstance(key, instance);
      }
    }

    return instance;
  }

  /**
   * Execute the function [f], injecting any arguments.
   */
  dynamic callInjected(Function f) {
    var mirror = reflect(f);
    assert(mirror is ClosureMirror);
    var parameterResolution = _resolveParameters(mirror.function.parameters);
    return Function.apply(
        f, parameterResolution.positionalParameters, 
        parameterResolution.namedParameters);
  }

  Binding _getBinding(Key key) {
    var binding = _findBinding(key);
    
    if (binding == null) {
      key = new Key(Utils.typeOfTypeMirror(reflectType(key.type)), 
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
  
  Object _buildInstanceOf(Binding binding) {
    var dependencyResolution = _resolveDependencies(binding.dependencies);
    return binding.buildInstance(dependencyResolution);
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
  
  _ParameterResolution _resolveParameters(List<ParameterMirror> parameters) {
    var positionalParameters = parameters
        .where((parameter) => !parameter.isNamed)
        .map((parameter) =>
            getInstanceOf((parameter.type as ClassMirror).reflectedType,
                annotatedWith: Utils.findBindingAnnotation(parameter)))
        .toList(growable: false);
      
      var namedParameters = new Map<Symbol, Object>();
      parameters.forEach((parameter) {
        if (parameter.isNamed) {
          var parameterClassMirror = 
              (parameter.type as ClassMirror).reflectedType;
          var annotation = Utils.findBindingAnnotation(parameter);
          
          var key = new Key(
              parameterClassMirror,
              annotatedWith: annotation);
          
          if (containsBindingOf(key)) {
            namedParameters[parameter.simpleName] = 
                getInstanceOf(parameterClassMirror,
                  annotatedWith: annotation);
          }
        }
      });
      
      return new _ParameterResolution(positionalParameters, namedParameters);
  }

  void _registerBindings(Module module) => _bindings.addAll(module.bindings);

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

class _InjectorBinding extends Binding {
  Injector _injector;
  List<Dependency> _dependencies = [];
  
  _InjectorBinding(Injector injector) : 
    super(Injector.key) {
    _injector = injector;
  }
  
  Object buildInstance(DependencyResolution dependencyResolution) => _injector;
  
  Iterable<Dependency> get dependencies => 
      new UnmodifiableListView(_dependencies);
  
}

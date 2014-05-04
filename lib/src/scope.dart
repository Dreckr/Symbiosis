library symbiosis.scope;

import 'package:collection/collection.dart';
import 'binding.dart';
import 'key.dart';

/**
 * Scopes allow the injector to reuse instances of a biinding by defining their
 * lifetime.
 *
 * This abstract class defines the interface that must be implemented by any
 * scope.
 */
abstract class Scope {

  /// Returns whether this scopes in currently in progress
  bool get isInProgress;

  /// Stores an [instance] of [key]
  void storeInstance(Key key, Object instance);

  /// Returns whether this scope has an instance of [key]
  bool hasInstanceOf(Key key);

  /// Returns the stored instance of [key], if found
  Object getInstanceOf(Key key);

}

/// A scope for instances with a lifetime as long as the application.
class SingletonScope implements Scope {
  Map<Key, Object> _instancePool = new Map<Key, Object>();

  bool get isInProgress => true;

  Map<Key, Object> get instancePool => new UnmodifiableMapView(_instancePool);

  void storeInstance(Key key, Object instance) {
    if (_instancePool.containsKey(key)) {
      throw new StateError("Scope already has an instance of $key");
    }

    _instancePool[key] = instance;
  }

  @override
  bool hasInstanceOf(Key key) =>
      _instancePool.containsKey(key);

  @override
  Object getInstanceOf(Key key) =>
      _instancePool[key];

}

/// Encapsulates a binding, scoping its instances
class ScopedBinding implements Binding {
  final Scope _scope;
  final Binding _binding;

  ScopedBinding(Scope scope, Binding binding) :
    _scope = scope,
    _binding = binding;

  @override
  Object buildInstance(DependencyResolution dependencyResolution) {
    if (!_scope.isInProgress) {
      throw new ArgumentError("${scope} is not in progress");
    }

    if (_scope.hasInstanceOf(key)) {
      return _scope.getInstanceOf(key);
    } else {
      var instance = _binding.buildInstance(dependencyResolution);
      _scope.storeInstance(key, instance);

      return instance;
    }
  }

  @override
  Iterable<Dependency> get dependencies {
    if (_scope.isInProgress && _scope.hasInstanceOf(key)) {
      return [];
    } else {
      return _binding.dependencies;
    }
  }

  @override
  Key get key => _binding.key;

  @override
  Type get scope => _binding.scope;
}

/**
 * An annotation used by [DeclarativeModule] to scope bindings.
 *
 * Annotate a member of a [DeclarativeModule] to scope the binding it defines.
 * Such binding will be scoped to the scope defined by [scopeType]. The defined
 * scope must already be registered in your [Injector].
 */
class ScopeAnnotation {
  final Type scopeType;

  const ScopeAnnotation(this.scopeType);
}

/// A [ScopeAnnotation] for the [SingletonScope].
const Singleton = const ScopeAnnotation(SingletonScope);
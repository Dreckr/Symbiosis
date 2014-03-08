library dado.scope;

import 'package:collection/collection.dart';
import 'binding.dart';
import 'key.dart';

abstract class Scope {

  bool get isInProgress;

  Map<Key, Object> get instancePool;

  void storeInstance(Key key, Object instance);

  Binding scope(Binding binding);
}

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

  Binding scope(Binding binding) => new ScopedBinding(this, binding);

}

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

    if (_scope.instancePool.containsKey(key)) {
      return _scope.instancePool[key];
    } else {
      var instance = _binding.buildInstance(dependencyResolution);
      _scope.storeInstance(key, instance);

      return instance;
    }
  }

  @override
  Iterable<Dependency> get dependencies {
    if (_scope.isInProgress && _scope.instancePool.containsKey(key)) {
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
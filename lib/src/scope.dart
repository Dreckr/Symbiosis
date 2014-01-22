library dado.scope;

import 'package:collection/collection.dart';
import 'key.dart';

abstract class Scope {
  
  bool get isInProgress;
  
  Map<Key, Object> get instancePool;
  
  void storeInstance(Key key, Object instance);
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
}
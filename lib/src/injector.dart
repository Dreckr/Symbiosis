library symbiosis.injector;

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
  List<Binding> get bindings => new UnmodifiableListView(_bindings.values);

/// A unmodifiable list of all scopes registered in this injector.
  List<Scope> get scopes => new UnmodifiableListView(_scopes.values);

  _InjectionContext context;

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

  /// Returns an instance for [binding].
  Object getInstanceOfBinding(Binding binding) =>
      _getInstanceOfBinding(binding);

  Object _getInstanceOfBinding(Binding binding) {
    if (context == null) {
      context = new _InjectionContext(binding.key);
    } else {
      context.registerInjection(binding.key);
    }

    var instance = binding.buildInstance(_provide);

    context.unregisterLast();

    return instance;
  }

  _provide (Key key, [bool isOptional]) {
    var binding;
    if (isOptional) {
      binding = _findBinding(key);

      if (binding == null) {
        return null;
      }
    } else {
      binding = _getBinding(key);
    }

    return this._getInstanceOfBinding(binding);
  }

  Binding _getBinding(Key key) {
    var binding = _findBinding(key);

    if (binding == null) {
      throw new ArgumentError('$key has no binding.');
    }

    return binding;
  }

  Binding _findBinding(Key key) {
    return _bindings.containsKey(key)
      ? _bindings[key]
        : (parent != null)
          ? parent._findBinding(key)
            : null;
  }

  // Checks if there is a binding registered for [key]
  bool containsBindingOf(Key key) => _bindings.containsKey(key) ||
      (parent != null ? parent.containsBindingOf(key) : false);

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

  String toString() => 'Injector: $name';
}

class _InjectionContext {
  int _lastCheckIndex =  0;
  final List<Key> _injections;

  _InjectionContext (Key initialInjection) : _injections = [initialInjection];

  registerInjection (Key key) {
    _injections.add(key);

    if (_injections.length > _lastCheckIndex * 2) {
      _checkCircularDependency();
      _lastCheckIndex = _injections.length - 1;
    }
  }

  unregisterLast() {
    _injections.removeLast();
  }

  _checkCircularDependency() {
    for (int i = 0; i < _injections.length; i++) {
      var found = false;

      for (int j = i + 1; j < _injections.length; j++) {
        if (_injections[i] == _injections[j]) {
          found = true;
          break;
        }
      }

      if (found) {
        throw new ArgumentError(
            'Circular dependency found on type ${_injections[i].type}:\n');
      }
    }
  }

}

library symbiosis.binding;

import 'dart:collection';
import 'package:inject/inject.dart';
import 'key.dart';

/**
 * A general purpose [BindingAnnotation].
 *
 * This is an easy to use [BindingAnnotation] that uses a name to distiguish
 * itself from other annotations.
 */
class Named implements BindingAnnotation {
  final String name;

  const Named(this.name);

  bool operator ==(o) => o is Named && o.name == name;
}

/**
 * Bindings define the way that instances of a [Key] are created. They are used
 * to hide all the logic needed to build an instance and analyze its
 * dependencies.
 *
 * This is an interface, so there can be several types of Bindings, each one
 * with its own internal logic to build instances and define its scope.
 */
abstract class Binding {
  final Key key;
  final Type scope;

  Binding(this.key, {this.scope});

  Object buildInstance(DependencyResolution dependencyResolution);

  Iterable<Dependency> get dependencies;

}

/**
 * An implementation of [Binding] that binds a [Key] to a predefined instance.
 */
class InstanceBinding extends Binding {
  final Object instance;
  List<Dependency> _dependencies = [];

  InstanceBinding(Key key, this.instance) :
    super(key);

  Object buildInstance(DependencyResolution dependencyResolution) => instance;

  Iterable<Dependency> get dependencies =>
      new UnmodifiableListView(_dependencies);

}

/**
 * Dependencies define what instances are needed to construct a instance of a
 * binding. A dependency can be nullable, which means it doesn't need to be
 * satisfied. It can also be positional, which is the case of positional
 * arguments of a constructor.
 */
class Dependency {
  /// The name of this dependency. Usually the same name as a parameter.
  final Symbol name;

  /// The key that identifies the type of this dependency.
  final Key key;

  final bool isNullable;
  final bool isPositional;

  /// If this dependency [isPositional], this is its position.
  final int position;

  Dependency(this.name, this.key, {this.isNullable: false,
                                    this.isPositional: true,
                                    this.position: 0});
}

/**
 * A DependencyResolution provides everything that a binding may need to build a
 * instance.
 *
 * In an analogy to baking a cake, if the [Binding] is a recipe, the
 * DependencyResolution would be its ingredients.
 */
class DependencyResolution {
  Map<Dependency, Object> instances;

  DependencyResolution([this.instances]) {
    if (this.instances == null) {
      this.instances = new Map<Dependency, Object>();
    }
  }

  Object operator [] (Dependency dependency) {
    return instances[dependency];
  }

  void operator []=(Dependency dependency, Object instance) {
      instances[dependency] = instance;
  }
}
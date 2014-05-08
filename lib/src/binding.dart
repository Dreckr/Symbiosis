library symbiosis.binding;

import 'package:inject/inject.dart';
import 'key.dart';

typedef dynamic InstanceProvider(Key key, [bool isOptional]);

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

  Object buildInstance(InstanceProvider instanceProvider);

}

/**
 * An implementation of [Binding] that binds a [Key] to a predefined instance.
 */
class InstanceBinding extends Binding {
  final Object instance;
  InstanceBinding(Key key, this.instance) :
    super(key);

  Object buildInstance(InstanceProvider instanceProvider) => instance;

}

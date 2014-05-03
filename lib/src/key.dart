library symbiosis.key;

import 'package:inject/inject.dart';
import 'injector.dart';

/**
 * Keys are used to resolve instances in an [Injector], they are used to
 * register bindings and request an object at the injection point.
 *
 * Keys consist of a [Type] and an optional [BindingAnnotation].
 */
class Key {
  final Type type;
  final BindingAnnotation annotation;

  Key(Type this.type, {Object annotatedWith}) :
      annotation = annotatedWith {
    if (type == null) throw new ArgumentError("type must not be null");
  }

  bool operator ==(o) => o is Key && o.type == type
      && o.annotation == annotation;

  int get hashCode => type.hashCode * 37 +
      (annotation != null ? annotation.hashCode : 0);

  String toString() => 'Key: $type'
      '${(annotation!=null?' annotated with $annotation': '')}';
}
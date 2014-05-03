// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dado.binding;

import 'dart:collection';
import 'dart:mirrors';
import 'package:inject/inject.dart';
import 'key.dart';
import 'utils.dart' as Utils;

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
 * An implementation of [Binding] that binds a [Key] to a provider function.
 *
 * A provider can be a [Function] or a [ClosureMirror]. Using a [ClosureMirror]
 * allows you to use a class constructor or instance method as a provider with
 * the help of [ClassConstructorClosureMirrorAdapter] and
 * [InstanceMethodClosureMirrorAdapter].
 */
class ProviderBinding extends Binding {
  final ClosureMirror closureMirror;
  final MethodMirror methodMirror;
  List<Dependency> _dependencies;

  ProviderBinding(Key key, Function provider, {Type scope}) :
    this.withMirror(key, reflect(provider), scope: scope);

  ProviderBinding.withMirror(Key key,
                             ClosureMirror closureMirror,
                             {Type scope}) :
                              super(key, scope: scope),
                              closureMirror = closureMirror,
                              methodMirror = closureMirror.function;

  Object buildInstance(DependencyResolution dependencyResolution) {
    if (!_satisfiesDependencies(dependencyResolution)) {
      throw new ArgumentError('Dependencies were not satisfied');
    }

    var positionalArguments =
          _getPositionalArgsFromResolution(dependencyResolution);
    var namedArguments =
          _getNamedArgsFromResolution(dependencyResolution);

    return closureMirror.apply(positionalArguments, namedArguments).reflectee;
  }

  Iterable<Dependency> get dependencies {
      if (_dependencies == null) {
        _dependencies = new List<Dependency>(methodMirror.parameters.length);
        int position = 0;

        methodMirror.parameters.forEach(
          (parameter) {
            var parameterType = (parameter.type as ClassMirror).reflectedType;
            var annotation = Utils.findBindingAnnotation(parameter);

            var key = new Key(
                parameterType,
                annotatedWith: annotation);

            var dependency =
                new Dependency(parameter.simpleName,
                               key,
                               isNullable: parameter.isNamed ||
                                           parameter.isOptional,
                               isPositional: !parameter.isNamed,
                               position: position);

            _dependencies[position] = dependency;

            position++;
          });
      }

      return new UnmodifiableListView(_dependencies);
    }

  List<Object> _getPositionalArgsFromResolution(
        DependencyResolution dependencyResolution) {
      var positionalArgs = new List(dependencyResolution.instances.length);

      dependencyResolution.instances.forEach(
          (dependency, instance) {
            if (dependency.isPositional) {
              positionalArgs[dependency.position] = instance;
            }
          });

      return positionalArgs.where((e) => e != null).toList(growable: false);
    }

    Map<Symbol, Object> _getNamedArgsFromResolution(
        DependencyResolution dependencyResolution) {
      var namedArgs= new Map();

      dependencyResolution.instances.forEach(
          (dependency, instance) {
            if (!dependency.isPositional) {
              namedArgs[dependency.name] = instance;
            }
          });

      return namedArgs;
    }

    bool _satisfiesDependencies(DependencyResolution resolution) =>
      dependencies.every((dependency) =>
        dependency.isNullable || resolution[dependency] != null);
}

/**
 * An implementation of [Binding] that binds a [Key] to a constructor.
 *
 * The constructor used is automatically selected by this binding.
 * The [Type] binded by a [ConstructorBinding] must have only one constructor,
 * a constructor annotated with `@inject` or at least a no-args constructor.
 */
class ConstructorBinding extends ProviderBinding {

  ConstructorBinding(Key key, Type type, {Type scope}) :
    this.withMirror(key, reflectClass(type), scope: scope);

  ConstructorBinding.withMirror(Key key, ClassMirror classMirror, {Type scope}):
    super.withMirror(key,
              new ClassConstructorClosureMirrorAdapter(classMirror,
                                                selectConstructor(classMirror)),
              scope: scope);

  static MethodMirror selectConstructor(ClassMirror m) {
    Iterable<MethodMirror> constructors = Utils.getConstructorsMirrors(m);
    // Choose contructor using @inject
    MethodMirror selectedConstructor = constructors.firstWhere(
      (constructor) => constructor.metadata.any(
        (metadata) => metadata.reflectee == inject)
      , orElse: () => null);

    // In case there is no constructor annotated with @inject, see if there's a
    // single constructor or a no-args.
    if (selectedConstructor == null) {
      if (constructors.length == 1) {
        selectedConstructor = constructors.first;
      } else {
        selectedConstructor = constructors.firstWhere(
            (constructor) => constructor.parameters.where(
                (parameter) => !parameter.isOptional).length == 0
        , orElse: () =>  null);
      }
    }

    if (selectedConstructor == null) {
      throw new ArgumentError("${m.qualifiedName} must have only "
        "one constructor, a constructor annotated with @inject or no-args "
        "constructor");
    }

    return selectedConstructor;
  }

}

/**
 * A binding that binds a [Key] to another binding.
 *
 * This binding can be useful when binding an abstract class to one of its
 * implementations.
 */
class Rebinding extends Binding {
  Key rebindingKey;

  Rebinding(Key key, this.rebindingKey, {Type scope}) :
    super(key, scope: scope);

  Iterable<Dependency> get dependencies =>
      [new Dependency(#rebind,rebindingKey)];

  @override
  Object buildInstance(DependencyResolution dependencyResolution) =>
      dependencyResolution.instances.values.first;

}

/**
 * An implementation of [ClosureMirror] that allows us to call an instance
 * method as if it was a closure. This is like the reflective version of a
 * wannabe function.
 */
class InstanceMethodClosureMirrorAdapter implements ClosureMirror {
  final InstanceMirror instanceMirror;
  final MethodMirror methodMirror;

  InstanceMethodClosureMirrorAdapter(this.instanceMirror, this.methodMirror);

  @override
  InstanceMirror apply(List positionalArguments,
                       [Map<Symbol, dynamic> namedArguments]) =>
      instanceMirror.invoke(methodMirror.simpleName,
                                  positionalArguments,
                                  namedArguments);

  @override
  delegate(Invocation invocation) => instanceMirror.delegate(invocation);

  @override
  InstanceMirror findInContext(Symbol name, {ifAbsent: null}) =>
      throw new UnsupportedError("Unsupported");

  @override
  MethodMirror get function => methodMirror;

  @override
  InstanceMirror getField(Symbol fieldName) =>
      instanceMirror.getField(fieldName);

  @override
  bool get hasReflectee => instanceMirror.hasReflectee;

  @override
  InstanceMirror invoke(Symbol memberName,
                         List positionalArguments,
                         [Map<Symbol, dynamic> namedArguments]) =>
    instanceMirror.invoke(memberName, positionalArguments, namedArguments);

  @override
  get reflectee => instanceMirror.reflectee;

  @override
  InstanceMirror setField(Symbol fieldName, Object value) =>
      instanceMirror.setField(fieldName, value);

  @override
  ClassMirror get type => instanceMirror.type;
}

/**
 * An implementation of [ClosureMirror] that allows us to call a class
 * constructor as if it was a closure.
 */
class ClassConstructorClosureMirrorAdapter implements ClosureMirror {
  final ClassMirror classMirror;
  final MethodMirror constructorMirror;

  ClassConstructorClosureMirrorAdapter(this.classMirror, this.constructorMirror);

  @override
  InstanceMirror apply(List positionalArguments,
                       [Map<Symbol, dynamic> namedArguments]) =>
      classMirror.newInstance(constructorMirror.constructorName,
                                  positionalArguments,
                                  namedArguments);

  @override
  delegate(Invocation invocation) =>
      this.invoke(invocation.memberName,
                             invocation.positionalArguments,
                             invocation.namedArguments);

  @override
  InstanceMirror findInContext(Symbol name, {ifAbsent: null}) =>
      throw new UnsupportedError("Unsupported");

  @override
  MethodMirror get function => constructorMirror;

  @override
  InstanceMirror getField(Symbol fieldName) =>
      classMirror.getField(fieldName);

  @override
  bool get hasReflectee => classMirror.hasReflectedType;

  @override
  InstanceMirror invoke(Symbol memberName,
                         List positionalArguments,
                         [Map<Symbol, dynamic> namedArguments]) =>
    classMirror.newInstance(constructorMirror.constructorName,
                            positionalArguments,
                            namedArguments);

  @override
  get reflectee => classMirror.reflectedType;

  @override
  InstanceMirror setField(Symbol fieldName, Object value) =>
      classMirror.setField(fieldName, value);

  @override
  ClassMirror get type => classMirror;
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
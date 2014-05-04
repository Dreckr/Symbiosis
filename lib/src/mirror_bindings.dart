library symbiosis.binding.mirror;

import 'dart:collection';
import 'dart:mirrors';
import 'package:inject/inject.dart';
import 'binding.dart';
import 'key.dart';
import 'utils.dart' as Utils;

/**
 * An implementation of [Binding] that binds a [Key] to a provider function.
 *
 * A provider can be a [Function] or a [ClosureMirror]. Using a [ClosureMirror]
 * allows you to use a class constructor or instance method as a provider with
 * the help of [ClassClosureMirrorAdapter] and
 * [InstanceClosureMirrorAdapter].
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
              new ClassClosureMirrorAdapter(classMirror,
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
class InstanceClosureMirrorAdapter implements ClosureMirror {
  final InstanceMirror instanceMirror;
  final MethodMirror methodMirror;

  InstanceClosureMirrorAdapter(this.instanceMirror, this.methodMirror);

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
class ClassClosureMirrorAdapter implements ClosureMirror {
  final ClassMirror classMirror;
  final MethodMirror constructorMirror;

  ClassClosureMirrorAdapter(this.classMirror, this.constructorMirror);

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

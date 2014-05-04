library symbiosis.module.declarative;

import 'dart:collection';
import 'dart:mirrors';
import 'binding.dart';
import 'key.dart';
import 'mirror_bindings.dart';
import 'module.dart';
import 'scope.dart';
import 'utils.dart' as Utils;


/**
 * A declarative implementation of [Module].
 *
 * In this kind of module, bindings are defined in a declarative manner.
 *
 * Bindings are declared with members on a DeclarativeModule. The return type of the member
 * defines what type the binding is for. The type of member (variable, getter,
 * method) defines the type of binding:
 *
 * * Unitialized variables define constructor bindings.
 *   See also [ConstructorBinding].
 * * Initialized variables define instance bindings. The type of the variable is
 *   bound to its value.
 * * Method or getters define provider bindings. The return type is bound to
 *   this method or getter.
 *
 * This bindings can be scoped using a [ScopeAnnotation]. For example, if you
 * want to make a binding a singleton, you only have to annotate the member that
 * defines such binding with [Singleton].
 *
 * Example
 * -------
 *
 * import 'package:symbiosis/symbiosis.dart';
 *
 * class MyDeclarativeModule extends DeclarativeModule {
 *
 *   // Defines a constructor binding for a type
 *   Foo foo;
 *
 *   // Binds a type to an instance
 *   Qux qux = new Qux();
 *
 *   // Defines an alternative binding for type Foo by passing annotating it with
 *   // a BindingAnnotation
 *   @Named("b")
 *   Foo alteranativeFoo = new Foo.b();
 *
 *   // Binds a provider function to a type
 *   Provided provided(Foo foo) => new Provided(foo);
 *
 *   // Defines a scoped constructor binding
 *   // Any type of binding can be scoped by annotating it with a ScopeAnnotation.
 *   @Singleton
 *   Scoped scope;
 * }
 */
abstract class DeclarativeModule implements Module {
  bool _initialized = false;
  List<Binding> _bindings = new List<Binding>();
  List<Scope> _scopes = new List<Scope>();

  @override
  List<Binding> get bindings => new UnmodifiableListView(_bindings);

  List<Scope> get scopes => new UnmodifiableListView(_scopes);

  DeclarativeModule() {
    _readModule();
  }

  @override
  void install(Module module) {
    _scopes.addAll(module.scopes);
    _bindings.addAll(module.bindings);
  }

  void _readModule() {
    var moduleMirror = reflect(this);
    var classMirror = moduleMirror.type;

    classMirror.declarations.values.forEach((member) {
      var bindingAnnotation = Utils.findBindingAnnotation(member);
      var scopeAnnotation = Utils.findScopeAnnotation(member);
      var scopeType;

      if (scopeAnnotation != null) {
        scopeType = scopeAnnotation.scopeType;
      }

      if (member is VariableMirror &&
          member.type != currentMirrorSystem().dynamicType) {
        // Variables define "to instance" bindings
        var instance = moduleMirror.getField(member.simpleName).reflectee;
        var type = member.type.reflectedType;
        var key = new Key(type, annotatedWith: bindingAnnotation);

        if (instance != null) {
          if (instance is Scope) {
            _scopes.add(instance);
          } else {
            _bindings.add(new InstanceBinding(key, instance));
          }
        } else {
          if (!(member.type is ClassMirror)) {
            throw new ArgumentError(
                '${member.type.simpleName} is not a class '
                'and can not be used in a constructor binding.');
          }

          _bindings.add(new ConstructorBinding.withMirror(key,
                                                member.type,
                                                scope: scopeType));
        }

      } else if (member is MethodMirror &&
                  !member.isConstructor &&
                  !member.isSetter) {
        var type = member.returnType.reflectedType;
        Key key = new Key(type, annotatedWith: bindingAnnotation);

        _bindings.add(new ProviderBinding.withMirror(key,
                         new InstanceClosureMirrorAdapter(moduleMirror, member),
                         scope: scopeType));
      }
    });
  }

}

/**
 * Dado's declarative library.
 *
 * This library contains the [DeclarativeModule], that is, as it name suggests,
 * a declarative implementation of [Module].
 */
library symbiosis.declarative;

import 'dart:collection';
import 'dart:mirrors';
import 'binding.dart';
import 'key.dart';
import 'module.dart';
import 'scope.dart';
import 'utils.dart' as Utils;


/**
 * A declarative implementation of [Module].
 *
 * In this kind of module, bindings are defined in a declarative manner.
 *
 * Bindings are declared with members on a Module. The return type of the member
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
 *     import 'package:dado/dado.dart';
 *
 *     class MyModule extends DeclarativeModule {
 *
 *       // Initialized variable define a binding to an instance.
 *       String serverAddress = "127.0.0.1";
 *
 *       // Unitialized variable define a binding to a constructor.
 *       Bar newBar;
 *
 *       // Getter define a binding to a getter.
 *       Foo get foo => new Foo('getter');
 *
 *       // Bindings can be made to provider methods
 *       Qux newQux (Foo foo) => new Qux(foo, 'not injected');
 *
 *       // Provider bindings can bind a type to an specific implementation of
 *       // that type.
 *       Baz subBaz (SubBaz subBaz) => subBaz;
 *
 *     }
 *
 *     class Bar {
 *       // A default constructor is automatically injected with dependencies.
 *       Bar(Foo foo);
 *     }
 *
 *     main() {
 *      var injector = new Injector([new MyModule()]);
 *      Bar bar = injector.getInstanceOf(Bar);
 *     }
 */
abstract class DeclarativeModule implements Module {
  bool _initialized = false;
  List<Binding> _bindings = new List();
  List<Scope> _scopes = new List();

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
        // Non-abstract methods produce instances by being invoked.
        //
        // In order for the method to use the injector to resolve dependencies
        // it must be aware of the injector and the type we're trying to
        // construct so we set the module's _currentInjector and
        // _currentTypeName in the provider function.
        //
        // This is a slightly unfortunately coupling of Module to it's
        // injector, but the only way we could find to make this work. It's
        // a worthwhile tradeoff for having declarative bindings.
        _bindings.add(new ProviderBinding.withMirror(key,
                         new InstanceMethodClosureMirrorAdapter(moduleMirror, member),
                         scope: scopeType));
      }
    });
  }

}

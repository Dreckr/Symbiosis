// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Dado's declarative library.
 * 
 * This library contains the implementation of the [DeclarativeModule], that is,
 * as it name suggests, a declarative implementation of [Module].
 */
library dado.declarative;

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
 * defines what type the binding is for. The kind of member (variable, getter,
 * method) defines the type of binding:
 *
 * * Variables define instance bindings. The type of the variable is bound to
 *   its value.
 * * Abstract getters define singleton bindings.
 * * Abstract methods define unscoped bindings. A new instance is created every
 *   time [Injector.getInstance] is called.
 * * A non-abstract method must return instances of its return type. Getters 
 *   define singletons.
 * 
 * Example
 * -------
 *
 *     import 'package:dado/dado.dart';
 *
 *     class MyModule extends DeclarativeModule {
 *
 *       // binding to an instance, similar to toInstance() in Guice
 *       String serverAddress = "127.0.0.1";
 *
 *       // Getters define singletons, similar to in(Singleton.class) in Guice
 *       Foo get foo;
 *
 *       // Methods define a factory binding, similar to bind().to() in Guice
 *       Bar newBar();
 *
 *       // Methods that delegate to bindTo() bind a type to a specific
 *       // implementation of that type
 *       Baz baz(SubBaz subBaz) => subBaz;
 *       
 *       SubBaz get subBaz;
 *
 *       // Bindings can be made to provider methods
 *       Qux newQux(Foo foo) => new Qux(foo, 'not injected');
 *       }
 *
 *       class Bar {
 *         // A default method is automatically injected with dependencies
 *         Bar(Foo foo);
 *       }
 *
 *       main() {
 *         var injector = new Injector([MyModule]);
 *         Bar bar = injector.getInstance(Bar);
 *       }
 */
abstract class DeclarativeModule implements Module {
  @override
  Map<Key, Binding> get bindings {
    if (_bindings == null) {
      _readBindings();
    }
    
    return _bindings;
  }
  
  Map<Key, Binding> _bindings;
  
  @override
  void install(Module module) {
    if (_bindings == null) {
      _readBindings();
    }
    
    _bindings.addAll(module.bindings);
  }
  
  void _readBindings() {
    if (_bindings == null) {
      _bindings = new Map<Key, Binding>();
    }
    
    var moduleMirror = reflect(this);
    var classMirror = moduleMirror.type;

    classMirror.declarations.values.forEach((member) {
      var bindingAnnotation = Utils.findBindingAnnotation(member);
      var scopeAnnotation = Utils.findScopeAnnotation(member);
      var scopeType;
      
      if (scopeAnnotation != null) {
        scopeType = scopeAnnotation.scopeType;
      }
      
      if (member is VariableMirror) {
        // Variables define "to instance" bindings
        var instance = moduleMirror.getField(member.simpleName).reflectee;
        var type = Utils.typeOfTypeMirror(member.type);
        var key = new Key(type, annotatedWith: bindingAnnotation);
        
        if (instance != null) {
          _bindings[key] = new InstanceBinding(key, instance);
        } else {
          if (!(member.type is ClassMirror)) {
            throw new ArgumentError(
                '${member.type.simpleName} is not a class '
                'and can not be used in a constructor binding.');
          }
          
          _bindings[key] = 
              new ConstructorBinding.withMirror(key, 
                                                member.type,
                                                scope: scopeType);
        }
        
      } else if (member is MethodMirror && !member.isConstructor &&
                  !member.isGetter && !member.isSetter) {
      var type = Utils.typeOfTypeMirror(member.returnType);
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
        _bindings[key] =
            new ProviderBinding.withMirror(key, 
                         new InstanceMethodClosureMirror(moduleMirror, member),
                         scope: scopeType);
      }
    });
  }
  
}

class ScopeAnnotation {
  final Type scopeType;
  
  const ScopeAnnotation(this.scopeType);
}

const Singleton = const ScopeAnnotation(SingletonScope);
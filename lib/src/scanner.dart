library symbiosis.scanner;

import 'dart:collection';
import 'dart:mirrors';
import 'package:inject/inject.dart';
import 'basic_module.dart';
import 'binding.dart';
import 'module.dart';
import 'scope.dart';
import 'utils.dart' as Utils;

/**
 * [EXPERIMENTAL]
 *
 * An implementation of [Module] that scans [currentMirrorSystem] seeking for
 * bindings.
 *
 * Classes annotated with `@inject` will be binded. Optionally, this classes can
 * be annotated with a [BindingAnnotation] and a [ScopeAnnotation].
 */
class ScannerModule extends Module {
  List<Binding> _bindings = new List();
  List<Scope> _scopes = new List();

  @override
  List<Binding> get bindings => new UnmodifiableListView(_bindings);
  @override
  List<Scope> get scopes => new UnmodifiableListView(_scopes);

  ScannerModule() {
    scan();
  }

  void install(Module module) {
    _scopes.addAll(module.scopes);
    _bindings.addAll(module.bindings);
  }

  void scan() {
    currentMirrorSystem().libraries.forEach((uri, library) {
      library.declarations.forEach((name, declaration) {
        if (Utils.hasInjectAnnotation(declaration)) {
          registerBinding(declaration);
        }
      });
    });
  }

  void registerBinding(DeclarationMirror declaration) {

    var bindingBuilder;
    var scopeAnnotation = Utils.findScopeAnnotation(declaration);
    var implementedByAnnotation =
        Utils.findImplementedByAnnotation(declaration);
    var providerAnnotation =
        Utils.findProvidedByAnnotation(declaration);

    if (declaration is ClassMirror) {
      bindingBuilder = new BindingBuilder(declaration.reflectedType,
          Utils.findBindingAnnotation(declaration));
    } else {
      return;
    }

    if (scopeAnnotation != null) {
      bindingBuilder.scope = scopeAnnotation.scopeType;
    }

    if (implementedByAnnotation != null) {
      bindingBuilder.to = implementedByAnnotation.type;
    }

    if (providerAnnotation != null) {
      bindingBuilder.provider = providerAnnotation.provider;
    }

    _bindings.add(bindingBuilder.build());
  }

}

class ImplementedBy {
  final Type type;

  const ImplementedBy(this.type);
}

class ProvidedBy {
  final Function provider;

  const ProvidedBy(this.provider);
}
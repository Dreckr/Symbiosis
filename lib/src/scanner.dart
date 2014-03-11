library dado.scanner;

import 'dart:collection';
import 'dart:mirrors';
import 'package:inject/inject.dart';
import 'binding.dart';
import 'key.dart';
import 'module.dart';
import 'scope.dart';
import 'utils.dart' as Utils;

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
        if (declaration is ClassMirror) {
          if (declaration.metadata.any(
              (metadataMirror) => metadataMirror.reflectee == inject)) {
            var key = new Key(declaration.reflectedType,
                annotatedWith: Utils.findBindingAnnotation(declaration));
            var scope = Utils.findScopeAnnotation(declaration);
            var binding = new ConstructorBinding.withMirror(key, declaration,
                scope: scope != null ? scope.scopeType : null);

            _bindings.add(binding);
          }
        }
      });
    });
  }

}
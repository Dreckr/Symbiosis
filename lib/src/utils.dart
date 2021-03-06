library symbiosis.utils;

import 'package:inject/inject.dart';
import 'dart:mirrors';
import 'scanner.dart';
import 'scope.dart';

findMetadata (DeclarationMirror declarationMirror, test(metadataMirror)) {
  var metadataMirror = declarationMirror.metadata.firstWhere(
      test,
      orElse: () => null);

  if (metadataMirror != null) {
    return metadataMirror.reflectee;
  } else  {
    return null;
  }
}

BindingAnnotation findBindingAnnotation (DeclarationMirror declarationMirror)
  => findMetadata(declarationMirror,
                  (metadata) => metadata.reflectee is BindingAnnotation);

ScopeAnnotation findScopeAnnotation (DeclarationMirror declarationMirror) =>
    findMetadata(declarationMirror,
                 (metadata) => metadata.reflectee is ScopeAnnotation);

ImplementedBy findImplementedByAnnotation (DeclarationMirror declarationMirror)
  => findMetadata(declarationMirror,
                  (metadata) => metadata.reflectee is ImplementedBy);

ProvidedBy findProvidedByAnnotation (DeclarationMirror declarationMirror)
  => findMetadata(declarationMirror,
                  (metadata) => metadata.reflectee is ProvidedBy);

bool hasInjectAnnotation(DeclarationMirror declaration) =>
      declaration.metadata.any(
                  (metadataMirror) => metadataMirror.reflectee == inject);

List<MethodMirror> getConstructorsMirrors(ClassMirror classMirror) {
  var constructors = new List<MethodMirror>();

  classMirror.declarations.values.forEach((declaration) {
    if ((declaration is MethodMirror) && (declaration.isConstructor))
        constructors.add(declaration);
  });

  return constructors;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dado.utils;

import 'package:inject/inject.dart';
import 'dart:mirrors';
import 'key.dart';
import 'declarative.dart';

Key makeKey(dynamic k) => (k is Key) ? k : new Key(k);

Type typeOfTypeMirror(TypeMirror typeMirror) {
  if (typeMirror is ClassMirror) {
    return typeMirror.reflectedType;
  } else if (typeMirror is TypedefMirror) {
    return typeMirror.referent.reflectedType;
  } else {
    return null;
  }
}

BindingAnnotation findBindingAnnotation (DeclarationMirror declarationMirror) {
  var bindingMetadata = declarationMirror.metadata.firstWhere(
      (metadata) => metadata.reflectee is BindingAnnotation, 
      orElse: () => null);
  
  if (bindingMetadata != null) {
    return bindingMetadata.reflectee;
  } else  {
    return null;
  }
}

ScopeAnnotation findScopeAnnotation (DeclarationMirror declarationMirror) {
  var scopeMetadata = declarationMirror.metadata.firstWhere(
      (metadata) => metadata.reflectee is ScopeAnnotation, 
      orElse: () => null);
  
  if (scopeMetadata != null) {
    return scopeMetadata.reflectee;
  } else  {
    return null;
  }
}

List<MethodMirror> getConstructorsMirrors(ClassMirror classMirror) {
  var constructors = new List<MethodMirror>();

  classMirror.declarations.values.forEach((declaration) {
    if ((declaration is MethodMirror) && (declaration.isConstructor))
        constructors.add(declaration);
  });

  return constructors;
}
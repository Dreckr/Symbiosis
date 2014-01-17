// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dado.utils;

import 'dart:mirrors';
import 'key.dart';

Key makeKey(dynamic k) => (k is Key) ? k : new Key(k);

Type typeOfTypeMirror(TypeMirror typeMirror) {
  if (typeMirror is ClassMirror) {
    return typeMirror.reflectedType;
  } else if (typeMirror is TypedefMirror) {
    // TODO(diego): Use typeMirror.reflectedType when it becomes available
    return typeMirror.referent.reflectedType;
  } else {
    return null;
  }
}

Object getBindingAnnotation (DeclarationMirror declarationMirror) {
  List<InstanceMirror> metadata;
  metadata = declarationMirror.metadata;

  if (metadata.isNotEmpty) {
    // TODO(justin): what do we do when a declaration has multiple
    // annotations? What does Guice do? We should probably only allow one
    // binding annotation per declaration, which means we need a way to
    // identify binding annotations.
    return metadata.first.reflectee;
  }

  return null;
}

List<MethodMirror> getConstructorsMirrors(ClassMirror classMirror) {
  var constructors = new List<MethodMirror>();

  classMirror.declarations.values.forEach((declaration) {
    if ((declaration is MethodMirror) && (declaration.isConstructor))
        constructors.add(declaration);
  });

  return constructors;
}
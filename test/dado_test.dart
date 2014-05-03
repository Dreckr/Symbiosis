// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dado_test;

import 'binding/binding_implementations.dart';
import 'injector/injector.dart';
import 'key/key.dart';
import 'module/basic_module.dart';
import 'module/declarative_module.dart';
import 'scope/singleton_scope.dart';

// TODO(diego): Test scoped binding.
main() {
  testInjector();
  testBindingImplementations();
  testKey();
  testBasicModule();
  testDeclarativeModule();
  testSingletonScope();
}

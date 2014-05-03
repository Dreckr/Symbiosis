library symbiosis.test;

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

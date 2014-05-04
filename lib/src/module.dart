library symbiosis.module;

import 'binding.dart';
import 'injector.dart';
import 'scope.dart';

/**
 * A Module is a declaration of bindings that instruct an [Injector] how to
 * create objects.
 *
 * This abstract class defines the interface that must be implemented by any
 * module.
 */
abstract class Module {
  /// Bindings declared by this module.
  List<Binding> get bindings;

  /// Scopes provided by this module.
  List<Scope> get scopes;

  /// Installs a module into this. All bindings and scopes provided by [module]
  /// should also be provided by this.
  void install(Module module);
}

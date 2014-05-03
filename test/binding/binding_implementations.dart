library dado.test.binding.implementations;

import 'dart:mirrors';
import 'package:dado/dado.dart';
import 'package:unittest/unittest.dart';
import '../common.dart';

void testBindingImplementations() {
  group("Binding Implementations:", () {

    group("InstanceBinding:", () {
      var key;
      var binding;
      var instance;

      setUp(() {
        key = new Key(Foo);
        instance = new Foo("test");
        binding = new InstanceBinding(key, instance);
      });

      test("Has no dependency", () {
        expect(binding.dependencies, isEmpty);
      });

      test("Builds instance", () {
        var builtInstance = binding.buildInstance(new DependencyResolution());
        expect(identical(instance, builtInstance), isTrue);
      });
    });

    group("ProviderBinding:", () {
      var key;
      var noArgsProvider;
      var positionalProvider;
      var optionalPositionalProvider;
      var optionalNamedProvider;

      var noArgsBinding;
      var positionalBinding;
      var optionalPositionalBinding;
      var optionalNamedBinding;

      setUp(() {
        key = new Key(Foo);
        noArgsProvider = () => new Foo("test");
        positionalProvider = (String string) => new Foo(string);
        optionalPositionalProvider =
            ([String string = "test"]) => new Foo(string);
        optionalNamedProvider =
            ({String string: "test"}) => new Foo(string);

        noArgsBinding = new ProviderBinding(key, noArgsProvider);
        positionalBinding = new ProviderBinding(key, positionalProvider);
        optionalPositionalBinding =
            new ProviderBinding(key, optionalPositionalProvider);
        optionalNamedBinding = new ProviderBinding(key, optionalNamedProvider);
      });

      test("Parameters are mapped as dependencies", () {
        void testDependencyMapping
            (binding, [dependenciesLength = 0, isNullable, isPositional]) {
          var dependencies = binding.dependencies;
          expect(dependencies, hasLength(dependenciesLength));
          if (dependenciesLength == 1) {
            expect(dependencies[0].name, equals(#string));
            expect(dependencies[0].key, equals(new Key(String)));
            expect(dependencies[0].isNullable, isNullable);
            expect(dependencies[0].isPositional, isPositional);
          }
        };

        testDependencyMapping(noArgsBinding);
        testDependencyMapping(positionalBinding, 1, isFalse, isTrue);
        testDependencyMapping(optionalPositionalBinding, 1, isTrue, isTrue);
        testDependencyMapping(optionalNamedBinding, 1, isTrue, isFalse);
      });

      test("Builds instance", () {
        var dependencyResolution;

        void testInstantiation (binding, unresolvedMatcher) {
          var unresolvedInstantiation = () {
            dependencyResolution = new DependencyResolution();
            binding.buildInstance(dependencyResolution);
          };

          var dependencies = binding.dependencies;
          var instances = new Map();
          if (dependencies.length == 1) {
            instances[dependencies[0]] = "test";
          }

          dependencyResolution = new DependencyResolution(instances);
          expect(binding.buildInstance(dependencyResolution),
                 new isInstanceOf<Foo>());
          expect(
              unresolvedInstantiation,
              unresolvedMatcher);
        };

        testInstantiation(noArgsBinding, returnsNormally);
        testInstantiation(positionalBinding, throwsArgumentError);
        testInstantiation(optionalPositionalBinding, returnsNormally);
        testInstantiation(optionalNamedBinding, returnsNormally);
      });
    });

    group("ConstructorBinding:", () {
      test("Selects adequate constructor", () {
        void testConstructorSelection (type, [constructorName]) {
          var classMirror = reflectClass(type);
          var selectConstructor = () =>
            ConstructorBinding.selectConstructor(classMirror);

          if (constructorName != null) {
            expect(selectConstructor().constructorName,
                   equals(constructorName));
          } else {
            expect(selectConstructor, throwsArgumentError);
          }
        };

        testConstructorSelection(Foo, const Symbol(""));
        testConstructorSelection(HasAnnotatedConstructor, #annotated);
        testConstructorSelection(HasNoArgsConstructor, #noArgs);
        testConstructorSelection(HasMultipleUnannotatedConstructors);
      });
    });

    //  TODO(diego): test Rebinding
  });
}
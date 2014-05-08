library symbiosis.test.binding.implementations;

import 'dart:mirrors';
import 'package:symbiosis/symbiosis.dart';
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

      test("Builds instance", () {
        var builtInstance = binding.buildInstance((key, [isOptional]) => null);
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

      test("Builds instance", () {
        var dependencyResolution;

        void testInstantiation (binding, unresolvedMatcher) {
          var unresolvedInstantiation = () {
            binding.buildInstance((key, [isOptional]) {
              if (isOptional)
                return null;
              else
                throw new ArgumentError();
            });
          };

          expect(binding.buildInstance((key, [isOptional]) => "test"),
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
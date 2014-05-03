library symbiosis.test.injector;

import 'package:symbiosis/symbiosis.dart';
import 'package:unittest/unittest.dart';
import '../common.dart';

void testInjector() {
  group("Injector:",(){
    Injector injector;

    setUp((){
      injector = new Injector([new Module1()]);
    });

    test("Returns instance of binding with no dependency", () {
      expect(injector.getInstanceOf(String), "a");
    });

    test("Returns alternative instance of type with no dependency", () {
      expect(injector.getInstanceOf(String, annotatedWith: B), "b");
    });

    test("Returns a scoped instance", () {
      var foo1 = injector.getInstanceOf(Foo);
      var foo2 = injector.getInstanceOf(Foo);
      expect(foo1, new isInstanceOf<Foo>());
      expect(identical(foo1, foo2), true);
    });

    test("Returns instance of binding with dependency", () {
      var bar1 = injector.getInstanceOf(Bar);
      var bar2 = injector.getInstanceOf(Bar);
    });

    test("Provides binding with the same instance of scoped binding", () {
      var bar1 = injector.getInstanceOf(Bar);
      var bar2 = injector.getInstanceOf(Bar);
      expect(identical(bar1.foo, bar2.foo), true);
    });

    test("Returns a function", () {
      SomeFunctionType func = injector.getInstanceOf(SomeFunctionType);
      expect(func, new isInstanceOf<SomeFunctionType>());
    });

    test("Uses bindings from later modules", () {
      injector = new Injector([new Module1(), new Module2()]);
      var foo = injector.getInstanceOf(Foo);
      expect(foo, new isInstanceOf<Foo>());
      expect(foo.name, "foo2");
    });

    test("Injects itself", () {
      NeedsInjector o = injector.getInstanceOf(NeedsInjector);
      expect(o.injector, same(injector));
    });

    test("Injects named parameters when possible", () {
      var o = injector.getInstanceOf(HasSatisfiedNamedParameter);
      expect(o, new isInstanceOf<HasSatisfiedNamedParameter>());
      expect(o.a, "a");
    });

    test("Does not inject named parameters when impossible", () {
      var o = injector.getInstanceOf(HasUnsatisfiedNamedParameter);
      expect(o, new isInstanceOf<HasUnsatisfiedNamedParameter>());
      expect(o.a, null);
    });

    test("Throws ArgumentError on direct cyclical dependencies", () {
      expect(() => new Injector([new Module4()]), throwsArgumentError);
    });

    test("Throws ArgumentError on indirect cyclical dependencies", () {
      expect(() => new Injector([new Module5()]), throwsArgumentError);
    });

  });

  group("Child injector:", () {
    Injector injector;
    Injector childInjector;

    setUp((){
      injector = new Injector([new Module1()], name: "parent");
      childInjector = new Injector([new Module3()],
          sharedScopes: [SingletonScope],
          parent: injector,
          name: "child");
    });

    test("Uses shared scope", () {
      var foo1 = injector.getInstanceOf(Foo);
      var foo2 = childInjector.getInstanceOf(Foo);
      expect(foo1, same(foo2));
    });

    test("Uses a binding not in it's parent", () {
      try {
        var qux1 = injector.getInstanceOf(Qux);
        expect(true, isFalse);
      } on ArgumentError catch (e) {
        expect(true, isTrue);
      }

      var qux2 = childInjector.getInstanceOf(Qux);
      expect(qux2, new isInstanceOf<Qux>());
    });

    test("Uses a binding that overrides it's parent", () {
      var bar1 = injector.getInstanceOf(Bar);
      expect(bar1, new isInstanceOf<Bar>());
      var bar2 = childInjector.getInstanceOf(Bar);
      expect(bar2, new isInstanceOf<SubBar>());
    });

//    test("should inject itself, not it's parent", () {
//      injector.callInjected((Injector i) {
//        expect(i, same(injector));
//      });
//      childInjector.callInjected((Injector i) {
//        expect(i, same(childInjector));
//      });
//    });

    test("Injects itself into an instance of a binding defined in it's parent",
        () {
      var ni1 = injector.getInstanceOf(NeedsInjector);
      var ni2 = childInjector.getInstanceOf(NeedsInjector);
      expect(ni1.injector, same(injector));
      expect(ni2.injector, same(childInjector));
    });

    test("Does not share scope", () {
      var childInjector2 = new Injector([new Module3()],
          parent: injector, name: 'child 2');
      var qux1 = childInjector.getInstanceOf(Qux);
      var qux2 = childInjector2.getInstanceOf(Qux);
      expect(qux1, isNot(same(qux2)));
    });

  });
}
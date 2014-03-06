library dado.test.key;

import 'package:dado/dado.dart';
import 'package:unittest/unittest.dart';
import '../common.dart';

void testKey() {
  group('Key:', () {
    test('Instantiate simple key', () {
      var key = new Key(Foo);
      
      expect(key, new isInstanceOf<Key>());
      expect(key.type, equals(Foo));
      expect(key.annotation, isNull);
    });
    
    test('Instantiate annotated key', () {
      var key = new Key(Foo, annotatedWith: const Named('test'));
      
      expect(key, new isInstanceOf<Key>());
      expect(key.type, equals(Foo));
      expect(key.annotation, equals(const Named('test')));
    });
    
    test('Instantiate key with null type fails', () {
      var instantiation = () {
        var key = new Key(null);
      };
      
      expect(instantiation, throwsArgumentError);
    });
    
    test('Simple key equality', () {
      var a = new Key(Foo);
      var b = new Key(Foo);
      var c = new Key(Bar);
      
      expect(identical(a, b), isFalse);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
    
    test('Annotated key equality', () {
          var a = new Key(Foo, annotatedWith: const Named('test'));
          var b = new Key(Foo, annotatedWith: const Named('test'));
          var c = new Key(Foo, annotatedWith: const Named('test2'));
          var d = new Key(Foo);
          
          expect(identical(a, b), isFalse);
          expect(a, equals(b));
          expect(a, isNot(equals(c)));
          expect(a, isNot(equals(d)));
        });
  });
}
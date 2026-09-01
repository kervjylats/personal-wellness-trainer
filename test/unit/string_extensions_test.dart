import 'package:flutter_test/flutter_test.dart';
import 'package:personal_wellness_trainer/core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions', () {
    test('initials two words', () => expect('John Smith'.initials, 'JS'));
    test('initials one word', () => expect('Alice'.initials, 'A'));
    test('initials empty', () => expect(''.initials, ''));
    test('avatarInitials empty returns ?', () => expect(''.avatarInitials, '?'));
    test('avatarInitials spaces returns ?', () => expect('   '.avatarInitials, '?'));
    test('avatarInitials normal', () => expect('John Smith'.avatarInitials, 'JS'));
    test('capitalize', () => expect('hello world'.capitalize(), 'Hello world'));
    test('toTitleCase', () => expect('hello world'.toTitleCase(), 'Hello World'));
    test('isValidEmail true', () => expect('a@b.com'.isValidEmail, isTrue));
    test('isValidEmail false', () => expect('notanemail'.isValidEmail, isFalse));
    test('truncate short', () => expect('hi'.truncate(10), 'hi'));
    test('truncate long', () => expect('hello world'.truncate(5), 'he...'));
    test('nullable avatarInitials null', () => expect((null as String?).avatarInitials, '?'));
    test('nullable isNullOrEmpty null', () => expect((null as String?).isNullOrEmpty, isTrue));
    test('nullable isNullOrEmpty empty', () => expect(''.isNullOrEmpty, isTrue));
    test('nullable isNullOrEmpty value', () => expect('hello'.isNullOrEmpty, isFalse));
    test('orElse null', () => expect((null as String?).orElse('def'), 'def'));
    test('orElse value', () => expect('hi'.orElse('def'), 'hi'));
  });
}

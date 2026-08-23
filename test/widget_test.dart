import 'package:flutter_test/flutter_test.dart';
import 'package:footwear/core/utils/validators/auth_validator.dart';

void main() {
  test('auth validation accepts valid input', () {
    expect(AuthValidator.validateEmail('user@example.com'), isNull);
    expect(AuthValidator.validatePassword('secret1'), isNull);
    expect(AuthValidator.validateName('User'), isNull);
    expect(AuthValidator.validateConfirmPassword('secret1', 'secret1'), isNull);
  });
}

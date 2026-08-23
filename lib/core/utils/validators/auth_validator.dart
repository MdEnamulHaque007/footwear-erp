class AuthValidator {
  static String? validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validateName(String value) {
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? validateConfirmPassword(String password, String confirmation) {
    if (password != confirmation) return 'Passwords do not match';
    return null;
  }
}

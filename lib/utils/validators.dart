class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email cannot be empty';
    }

    final email = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }

    if (email.contains('..') || email.startsWith('.') || email.endsWith('.')) {
      return 'Invalid email format';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  static String? validatePasswordConfirmation(String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Password confirmation cannot be empty';
    }

    if (password != confirmation) {
      return 'Passwords do not match';
    }

    return null;
  }
}

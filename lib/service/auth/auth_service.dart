import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Set display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
        await credential.user?.reload();
      }

      // Save user data to Firestore
      if (credential.user != null) {
        await _userService.saveUser(
          firebaseUser: credential.user!,
          provider: 'email',
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update user data in Firestore (lastLogin, etc.)
      if (credential.user != null) {
        await _userService.saveUser(
          firebaseUser: credential.user!,
          provider: 'email',
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final credential = await _performGoogleSignIn();
      final userCredential = await _auth.signInWithCredential(credential);

      // Save user data to Firestore
      if (userCredential.user != null) {
        await _userService.saveUser(
          firebaseUser: userCredential.user!,
          provider: 'google',
        );
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Failed to send reset email: ${e.toString()}');
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    await _updateUserProfile(() async {
      final user = _requireUser();
      await user.updateDisplayName(displayName.trim());

      // Update Firestore as well
      await _userService.updateDisplayName(user.uid, displayName.trim());
    }, 'display name');
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _requireUser().updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to update password: ${e.toString()}');
    }
  }

  Future<void> reauthenticateWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await _requireUser().reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Re-authentication failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        GoogleSignIn.instance.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  User _requireUser() {
    final user = currentUser;
    if (user == null) {
      throw AuthException('No user is currently signed in');
    }
    return user;
  }

  Future<void> _updateUserProfile(
      Future<void> Function() updateFn,
      String fieldName,
      ) async {
    try {
      await updateFn();
      await _requireUser().reload();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to update $fieldName: ${e.toString()}');
    }
  }

  Future<AuthCredential> _performGoogleSignIn() async {
    try {
      GoogleSignInAccount? googleUser;

      if (GoogleSignIn.instance.supportsAuthenticate()) {
        final completer = Completer<GoogleSignInAccount?>();
        StreamSubscription<GoogleSignInAuthenticationEvent>? subscription;

        subscription = GoogleSignIn.instance.authenticationEvents.listen(
              (event) {
            if (!completer.isCompleted) {
              switch (event) {
                case GoogleSignInAuthenticationEventSignIn():
                  completer.complete(event.user);
                  subscription?.cancel();
                case GoogleSignInAuthenticationEventSignOut():
                  completer.complete(null);
                  subscription?.cancel();
              }
            }
          },
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
              subscription?.cancel();
            }
          },
        );

        try {
          await GoogleSignIn.instance.authenticate();
          googleUser = await completer.future.timeout(
            const Duration(seconds: 30),
          );
        } catch (e) {
          subscription.cancel();
          rethrow;
        }
      } else {
        throw AuthException('Google Sign-In is not supported on this platform');
      }

      if (googleUser == null) {
        throw AuthException('Google Sign-In was cancelled by the user');
      }

      final googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw AuthException('Failed to obtain ID token from Google');
      }

      return GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    } on GoogleSignInException catch (e) {
      throw _handleGoogleSignInException(e);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } on TimeoutException {
      throw AuthException('Google Sign-In timeout. Please try again.');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google Sign-In failed: ${e.toString()}');
    }
  }

  AuthException _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return AuthException('Password is too weak. Minimum 6 characters.');
      case 'email-already-in-use':
        return AuthException(
          'Email is already registered. Please login or use another email.',
        );
      case 'user-not-found':
        return AuthException(
          'Email not registered. Please sign up first.',
        );
      case 'wrong-password':
        return AuthException('Incorrect password. Please try again.');
      case 'invalid-credential':
        return AuthException('Invalid email or password.');
      case 'user-disabled':
        return AuthException(
          'This account has been disabled. Contact the administrator.',
        );
      case 'invalid-email':
        return AuthException('Invalid email format.');
      case 'too-many-requests':
        return AuthException(
          'Too many attempts. Please try again later.',
        );
      case 'requires-recent-login':
        return AuthException(
          'Sensitive operation. Please log out and log in again.',
        );
      case 'network-request-failed':
        return AuthException(
          'No internet connection. Check your connection.',
        );
      case 'operation-not-allowed':
        return AuthException('Operation not allowed. Contact the administrator.');
      default:
        return AuthException('Error: ${e.message ?? e.code}');
    }
  }

  AuthException _handleGoogleSignInException(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return AuthException('Google Sign-In cancelled by the user');
      default:
        return AuthException(
          'Google Sign-In error: ${e.description ?? e.code.name}',
        );
    }
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:anime_verse/service/auth/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  // Collection reference
  CollectionReference get _usersCollection =>
      _firestore.collection(_collectionName);

  /// Simpan atau update data user ke Firestore
  Future<void> saveUser({
    required User firebaseUser,
    required String provider,
  }) async {
    try {
      final userDoc = _usersCollection.doc(firebaseUser.uid);
      final docSnapshot = await userDoc.get();

      final now = DateTime.now();

      if (docSnapshot.exists) {
        // User sudah ada, update data
        await userDoc.update({
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName,
          'photoURL': firebaseUser.photoURL,
          'updatedAt': Timestamp.fromDate(now),
        });
      } else {
        // User baru, buat document baru
        final userModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
          provider: provider,
          createdAt: now,
          updatedAt: now,
        );

        await userDoc.set(userModel.toMap());
      }
    } catch (e) {
      throw Exception('Failed to save user data: ${e.toString()}');
    }
  }

  /// Ambil data user dari Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  /// Stream untuk realtime user data
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Update display name
  Future<void> updateDisplayName(String uid, String displayName) async {
    try {
      await _usersCollection.doc(uid).update({
        'displayName': displayName,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update display name: ${e.toString()}');
    }
  }

  /// Update photo URL
  Future<void> updatePhotoURL(String uid, String photoURL) async {
    try {
      await _usersCollection.doc(uid).update({
        'photoURL': photoURL,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update photo URL: ${e.toString()}');
    }
  }

  /// Delete user data
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user data: ${e.toString()}');
    }
  }

  /// Check if user exists in Firestore
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
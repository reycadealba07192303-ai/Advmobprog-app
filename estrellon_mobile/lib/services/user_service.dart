import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants.dart';
import '../models/login_type.dart';
import '../models/user_model.dart';

Map userMapData = {};
List userListData = [];

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  final firebase_auth.FirebaseAuth firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? get currentFirebaseUser => firebaseAuth.currentUser;

  Stream<firebase_auth.User?> get authStateChanges =>
      firebaseAuth.authStateChanges();

  // ── Firebase Auth ──────────────────────────────────────────────

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (firebaseAuth.currentUser != null) {
      await firebaseAuth.signOut();
    }
  }

  Future<void> updateUsername({required String username}) async {
    await firebaseAuth.currentUser?.updateDisplayName(username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await firebaseAuth.currentUser!.reauthenticateWithCredential(credential);
    await firebaseAuth.currentUser!.delete();
    await signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await firebaseAuth.currentUser!.reauthenticateWithCredential(credential);
    await firebaseAuth.currentUser!.updatePassword(newPassword);
  }

  Future<String?> getFirebaseIdToken({bool forceRefresh = false}) async {
    return firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }

  Future<Map<String, dynamic>> loginWithFirebase({
    required String email,
    required String password,
  }) async {
    await signIn(email: email, password: password);
    final token = await getFirebaseIdToken(forceRefresh: true);
    final firebaseUser = firebaseAuth.currentUser;

    final userData = {
      'uid': firebaseUser?.uid ?? '',
      'email': firebaseUser?.email ?? email,
      'firstName': firebaseUser?.displayName?.isNotEmpty == true ? firebaseUser!.displayName : email.split('@').first,
      'lastName': '',
      'username': firebaseUser?.displayName?.isNotEmpty == true
          ? firebaseUser!.displayName!
          : email.split('@').first,
      'type': 'editor',
    };

    if (firebaseUser != null) {
      final docRef = FirebaseFirestore.instance.collection('Users').doc(firebaseUser.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set(userData);
      } else {
        // Merge in case we want to update the document with the latest
        await docRef.set(userData, SetOptions(merge: true));
      }
    }

    return {
      'loginType': LoginType.firebase.storageValue,
      'token': token ?? '',
      ...userData
    };
  }

  Future<Map<String, dynamic>> registerWithFirebase({
    required Map<String, dynamic> user,
  }) async {
    final email = user['email']?.toString() ?? '';
    final password = user['password']?.toString() ?? '';

    await createAccount(email: email, password: password);

    final username = user['username']?.toString() ?? '';
    if (username.isNotEmpty) {
      await updateUsername(username: username);
    }

    final token = await getFirebaseIdToken(forceRefresh: true);
    final uid = firebaseAuth.currentUser?.uid ?? '';

    final userData = {
      'uid': uid,
      'email': email,
      'firstName': user['firstName']?.toString() ?? '',
      'lastName': user['lastName']?.toString() ?? '',
      'username': username.isNotEmpty ? username : email.split('@').first,
      'age': user['age']?.toString() ?? '',
      'gender': user['gender']?.toString() ?? '',
      'contactNumber': user['contactNumber']?.toString() ?? '',
      'address': user['address']?.toString() ?? '',
      'type': user['type']?.toString() ?? 'editor',
    };

    if (uid.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Users').doc(uid).set(userData);
    }

    return {
      'loginType': LoginType.firebase.storageValue,
      'token': token ?? '',
      ...userData
    };
  }

  // ── MongoDB / REST API ─────────────────────────────────────────

  static Future<List> getAllUsers() async {
    final response = await get(Uri.parse('$host/api/users'));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      userListData = decoded is List ? decoded : decoded['users'];
      return userListData;
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<Map> createUser(dynamic user) async {
    return registerUser(user);
  }

  Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> user,
  ) async {
    final response = await post(
      Uri.parse('$host/api/users'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(user),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      userMapData = decoded is Map ? decoded : {'user': decoded};
      return Map<String, dynamic>.from(userMapData);
    }

    String message = 'Registration failed';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        message = body['message'].toString();
      }
    } catch (_) {}

    throw Exception(message);
  }

  Future<Map<String, dynamic>> loginWithMongo({
    required String email,
    required String password,
  }) async {
    final response = await loginUser(email, password);
    response['loginType'] = LoginType.mongo.storageValue;
    return response;
  }

  Future<Map<String, dynamic>> registerWithMongo({
    required Map<String, dynamic> user,
  }) async {
    await registerUser(user);
    final email = user['email']?.toString() ?? '';
    final password = user['password']?.toString() ?? '';
    final loginResponse = await loginUser(email, password);
    loginResponse['loginType'] = LoginType.mongo.storageValue;
    return loginResponse;
  }

  Future<Map> updateUser(String id, dynamic user) async {
    final response = await put(
      Uri.parse('$host/api/users/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(user),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      userMapData = jsonDecode(response.body);
      return userMapData;
    } else {
      throw Exception(
        'Failed to update user: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> deleteMongoUser(String id) async {
    final response = await delete(Uri.parse('$host/api/users/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account');
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await post(
      Uri.parse('$host/api/users/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      data = Map<String, dynamic>.from(jsonDecode(response.body));
      return data;
    } else {
      throw Exception('Failed to load data');
    }
  }

  // ── Session helpers ────────────────────────────────────────────

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = userData['user'];
    final source = user is Map ? Map<String, dynamic>.from(user) : userData;

    await prefs.setString(
      'loginType',
      userData['loginType']?.toString() ??
          LoginType.mongo.storageValue,
    );
    await prefs.setString('uid', source['uid']?.toString() ?? source['_id']?.toString() ?? '');
    await prefs.setString('firstName', source['firstName']?.toString() ?? '');
    await prefs.setString('lastName', source['lastName']?.toString() ?? '');
    await prefs.setString('token', userData['token']?.toString() ?? '');
    await prefs.setString('type', source['type']?.toString() ?? '');
    await prefs.setString('email', source['email']?.toString() ?? '');
    await prefs.setString('username', source['username']?.toString() ?? '');
    await prefs.setString('age', source['age']?.toString() ?? '');
    await prefs.setString('gender', source['gender']?.toString() ?? '');
    await prefs.setString(
      'contactNumber',
      source['contactNumber']?.toString() ?? '',
    );
    await prefs.setString('address', source['address']?.toString() ?? '');
    await prefs.setBool('isActive', source['isActive'] == true);
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'loginType': prefs.getString('loginType') ?? LoginType.mongo.storageValue,
      'uid': prefs.getString('uid') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'token': prefs.getString('token') ?? '',
      'type': prefs.getString('type') ?? '',
      'email': prefs.getString('email') ?? '',
      'username': prefs.getString('username') ?? '',
      'age': prefs.getString('age') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'contactNumber': prefs.getString('contactNumber') ?? '',
      'address': prefs.getString('address') ?? '',
      'isActive': prefs.getBool('isActive') ?? true,
    };
  }

  Future<LoginType> getLoginType() async {
    final data = await getUserData();
    return LoginTypeX.from(data['loginType']?.toString());
  }

  Future<bool> isLoggedIn() async {
    final loginType = await getLoginType();
    if (loginType == LoginType.firebase && firebaseAuth.currentUser != null) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await logoutSession();
  }

  Future<void> logoutSession() async {
    final loginType = await getLoginType();
    if (loginType == LoginType.firebase) {
      await signOut();
    }
    await _clearStoredUserData();
  }

  Future<void> updateUsernameForSession({
    required String username,
    required LoginType loginType,
    String? uid,
  }) async {
    if (loginType == LoginType.firebase) {
      await updateUsername(username: username);
    } else if (uid != null && uid.isNotEmpty) {
      await updateUser(uid, {'username': username});
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<void> changePasswordForSession({
    required LoginType loginType,
    required String email,
    required String currentPassword,
    required String newPassword,
    String? uid,
  }) async {
    if (loginType == LoginType.firebase) {
      await resetPasswordFromCurrentPassword(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } else if (uid != null && uid.isNotEmpty) {
      await updateUser(uid, {'password': newPassword});
    } else {
      throw Exception('User ID not found');
    }
  }

  Future<void> deleteAccountForSession({
    required LoginType loginType,
    required String email,
    required String password,
    String? uid,
  }) async {
    if (loginType == LoginType.firebase) {
      await deleteAccount(email: email, password: password);
    } else if (uid != null && uid.isNotEmpty) {
      await deleteMongoUser(uid);
    } else {
      throw Exception('User ID not found');
    }
    await _clearStoredUserData();
  }

  Future<void> refreshFirebaseTokenIfNeeded() async {
    if (await getLoginType() != LoginType.firebase) return;
    final token = await getFirebaseIdToken(forceRefresh: true);
    if (token == null || token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> _clearStoredUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

User userFromLoginResponse(Map<String, dynamic> response) {
  final userData = response['user'];
  if (userData is Map) {
    return User.fromJson(Map<String, dynamic>.from(userData));
  }

  return User(
    uid: '',
    firstName: response['firstName']?.toString() ?? '',
    lastName: response['lastName']?.toString() ?? '',
    age: response['age']?.toString() ?? '',
    gender: response['gender']?.toString() ?? '',
    contactNumber: response['contactNumber']?.toString() ?? '',
    email: response['email']?.toString() ?? '',
    username: response['username']?.toString() ?? '',
    address: response['address']?.toString() ?? '',
    isActive: true,
    type: response['type']?.toString() ?? '',
  );
}

User userFromStoredData(Map<String, dynamic> data) {
  return User(
    uid: data['uid']?.toString() ?? '',
    firstName: data['firstName']?.toString() ?? '',
    lastName: data['lastName']?.toString() ?? '',
    age: data['age']?.toString() ?? '',
    gender: data['gender']?.toString() ?? '',
    contactNumber: data['contactNumber']?.toString() ?? '',
    email: data['email']?.toString() ?? '',
    username: data['username']?.toString() ?? '',
    address: data['address']?.toString() ?? '',
    isActive: data['isActive'] == true,
    type: data['type']?.toString() ?? '',
  );
}

String firebaseAuthErrorMessage(Object error) {
  if (error is firebase_auth.FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
  return error.toString();
}

String authErrorMessage(Object error, LoginType loginType) {
  if (loginType == LoginType.firebase) {
    return firebaseAuthErrorMessage(error);
  }
  final message = error.toString();
  if (message.startsWith('Exception: ')) {
    return message.replaceFirst('Exception: ', '');
  }
  return message;
}

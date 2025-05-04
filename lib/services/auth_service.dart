// services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  final DatabaseService _dbService = DatabaseService();

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isOwner => _currentUser?.role == UserRole.owner;
  bool get isCustomer => _currentUser?.role == UserRole.customer;

  // Mã hóa mật khẩu
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Đăng nhập
  Future<bool> login(String email, String password) async {
    try {
      final hashPassword = _hashPassword(password);
      
      final user = await _dbService.usersCollection.findOne(
        where.eq('email', email).eq('password', hashPassword)
      );

      if (user != null) {
        _currentUser = User.fromMap(user);
        await _saveUserSession(_currentUser!.id.toHexString());
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      return false;
    }
  }

  // Đăng ký
  Future<bool> register(User user) async {
    try {
      // Kiểm tra email đã tồn tại chưa
      final existingUser = await _dbService.usersCollection.findOne(
        where.eq('email', user.email)
      );

      if (existingUser != null) {
        return false; // Email đã tồn tại
      }

      // Mã hóa mật khẩu trước khi lưu
      user.password = _hashPassword(user.password);
      
      // Lưu user mới vào database
      await _dbService.usersCollection.insert(user.toMap());
      
      _currentUser = user;
      await _saveUserSession(user.id.toHexString());
      notifyListeners();
      
      return true;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      return false;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }

  // Khôi phục phiên đăng nhập
  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId == null) {
        return false;
      }
      
      final user = await _dbService.usersCollection.findOne(
        where.eq('_id', ObjectId.parse(userId))
      );
      
      if (user != null) {
        _currentUser = User.fromMap(user);
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Lỗi khôi phục phiên: $e');
      return false;
    }
  }

  // Cập nhật thông tin người dùng
  Future<bool> updateUser(User user) async {
    try {
      await _dbService.usersCollection.update(
        where.eq('_id', user.id),
        user.toMap()
      );
      
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      print('Lỗi cập nhật người dùng: $e');
      return false;
    }
  }

  // Cập nhật điểm tích lũy
  Future<bool> updatePoints(int additionalPoints) async {
    try {
      if (_currentUser != null) {
        _currentUser!.points += additionalPoints;
        
        await _dbService.usersCollection.update(
          where.eq('_id', _currentUser!.id),
          {
            '\$set': {'points': _currentUser!.points}
          }
        );
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Lỗi cập nhật điểm: $e');
      return false;
    }
  }

  // Lưu phiên đăng nhập
  Future<void> _saveUserSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }
}
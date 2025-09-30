// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'dart:convert';
// import '../models/todo_item.dart';

// class StorageHelper {
//   static final _storage = FlutterSecureStorage();
//   static const _key = 'todos';

//   //daily todo저장
//   static Future<void> saveDailyTodos(List<TodoItem> todos, String key) async {
//     final jsonString = jsonEncode(todos.map((e) => e.toJson()).toList());
//     await _storage.write(key: key, value: jsonString);
//   }

//   //daily todo불러오기
//   static Future<List<TodoItem>> loadDailyTodos(String key) async {
//     final jsonString = await _storage.read(key: key);
//     if (jsonString == null) return [];
//     final List jsonList = jsonDecode(jsonString);
//     return jsonList.map((e) => TodoItem.fromJson(e)).toList();
//   }

//   static Future<void> saveTodos(List<TodoItem> todos) async {
//     final jsonList = todos.map((e) => e.toJson()).toList();
//     final jsonString = jsonEncode(jsonList);
//     await _storage.write(key: _key, value: jsonString);
//   }

//   static Future<List<TodoItem>> loadTodos() async {
//     final jsonString = await _storage.read(key: _key);
//     if (jsonString == null) return [];
//     final List decoded = jsonDecode(jsonString);
//     return decoded.map((e) => TodoItem.fromJson(e)).toList();
//   }

//   static Future<void> clearTodos() async {
//     await _storage.delete(key: _key);
//   }
// }

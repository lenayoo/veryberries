import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/todo_item.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // userId는 로그인 안 한다고 했으니 기기별 UUID 등을 나중에 넣을 수 있음 (지금은 testUser)
  final String userId = "testUser";
  final String docId = "testId";

  /// 월별 투두 추가
  Future<DocumentReference> addMonthlyTodo(TodoItem todo) async {
    final docRef = await _db
        .collection('users')
        .doc(userId)
        .collection('monthly')
        .add(todo.toMap());

    return docRef;
  }

  /// 일별 투두 추가
  Future<DocumentReference> addDailyTodo(TodoItem todo, String dateKey) async {
    final docRef = await _db
        .collection('users')
        .doc(userId)
        .collection('daily')
        .add(todo.toMap());

    return docRef;
  }

  /// 월별 불러오기
  Future<List<TodoItem>> getMonthlyTodos() async {
    final snapshot =
        await _db.collection('users').doc(userId).collection('monthly').get();

    return snapshot.docs.map((d) => TodoItem.fromMap(d.data(), d.id)).toList();
  }

  /// 일별 불러오기
  Future<List<TodoItem>> getDailyTodos(String dateKey) async {
    final snapshot =
        await _db.collection('users').doc(userId).collection('daily').get();

    return snapshot.docs.map((d) => TodoItem.fromMap(d.data(), d.id)).toList();
  }

  /// 월별 isDone수정하기
  Future<void> updateMonthlyTodoIsDone(String docId, bool newValue) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('monthly')
        .doc(docId)
        .update({'isDone': newValue});
  }

  /// 일별 isDone수정하기
  Future<void> updateDailyTodoIsDone(String docId, bool newValue) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc('testUser')
        .collection('daily')
        .doc(docId)
        .update({'isDone': newValue});
  }

  /// 삭제
  Future<void> deleteTodo(String docPath) async {
    await _db.doc(docPath).delete();
  }
}

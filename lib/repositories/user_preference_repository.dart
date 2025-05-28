import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/preference.dart';

class UserPreferenceRepository {
  final _collection = FirebaseFirestore.instanceFor(
    app: FirebaseFirestore.instance.app,
    databaseId: 'preference',
  ).collection('preference');

  Future<Preference?> fetchPreference(String userId) async {
    final doc = await _collection.doc(userId).get();
    if (doc.exists) {
      return Preference.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> setPreference(Preference pref) async {
    await _collection.doc(pref.userId).set(pref.toMap());
  }

  Future<void> updatePreferenceField(String userId, Map<String, dynamic> data) async {
    await _collection.doc(userId).set(data, SetOptions(merge: true));
  }
} 
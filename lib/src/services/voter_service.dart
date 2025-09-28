import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voter.dart';

class VoterService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col() =>
      _db.collection('voters');

  Query<Map<String, dynamic>> _baseQuery() => _col();

  Query<Map<String, dynamic>> globalSearch(String q) {
    final text = q.trim().toLowerCase();
    if (text.isEmpty) return _baseQuery().limit(200);
    return _baseQuery()
        .where('NAME_lower', isGreaterThanOrEqualTo: text)
        .where('NAME_lower', isLessThan: '${text}z')
        .limit(1000);
  }

  Query<Map<String, dynamic>> bySector(String sector) =>
      _baseQuery().where('SECTOR', isEqualTo: sector);

  Query<Map<String, dynamic>> byBuilding(String buildingName) =>
      _baseQuery().where('BUILDING_NAME', isEqualTo: buildingName);

  Future<List<Voter>> votersByFlat(String building, String flat) async {
    final qs = await _baseQuery()
        .where('BUILDING_NAME', isEqualTo: building)
        .where('FLAT_NUMBER', isEqualTo: flat)
        .get();
    return qs.docs.map((d) => Voter.fromMap(d.id, d.data())).toList();
  }

  Future<void> upsertVoter(String? id, Map<String, dynamic> data) async {
    data['NAME_lower'] = (data['NAME'] ?? '').toString().toLowerCase();
    if (id == null) {
      await _col().add(data); // ✅ fixed
    } else {
      await _col().doc(id).set(data, SetOptions(merge: true));
    }
  }
}

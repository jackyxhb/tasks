import '../../../core/utils/phone_normalizer.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../domain/entities/person_entity.dart';
import '../database_executor.dart';
import '../database_value_codec.dart';

class PersonRepository {
  const PersonRepository(this.executor);

  final DatabaseExecutor executor;

  Future<void> save(PersonEntity person) {
    return executor.execute(
      'INSERT OR REPLACE INTO people ('
      'id, name, name_normalized, phone, role_hint, company, notes, created_at, updated_at'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        person.id,
        person.name,
        person.nameNormalized,
        person.phone,
        person.roleHint,
        person.company,
        person.notes,
        person.createdAt.toUtc().toIso8601String(),
        person.updatedAt.toUtc().toIso8601String(),
      ],
    );
  }

  Future<PersonEntity?> findById(String id) async {
    final rows = await executor.query(
      'SELECT * FROM people WHERE id = ? LIMIT 1',
      <Object?>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  Future<List<PersonEntity>> suggest({String? query, int limit = 10}) async {
    final normalizedQuery = TextNormalizer.normalizeNullable(query);
    final normalizedPhone = PhoneNormalizer.normalizeNullable(query);

    if (normalizedQuery == null && normalizedPhone == null) {
      final rows = await executor.query(
        'SELECT * FROM people ORDER BY updated_at DESC LIMIT ?',
        <Object?>[limit],
      );
      return rows.map(_fromRow).toList(growable: false);
    }

    final clauses = <String>[];
    final parameters = <Object?>[];

    if (normalizedQuery != null) {
      clauses.add('name_normalized LIKE ?');
      parameters.add('%$normalizedQuery%');
    }
    if (normalizedPhone != null) {
      clauses.add('phone LIKE ?');
      parameters.add('%$normalizedPhone%');
    }

    final rows = await executor.query(
      'SELECT * FROM people WHERE ${clauses.join(' OR ')} '
      'ORDER BY updated_at DESC LIMIT ?',
      <Object?>[...parameters, limit],
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  PersonEntity _fromRow(DatabaseRow row) {
    return PersonEntity(
      id: DatabaseValueCodec.string(row['id']),
      name: DatabaseValueCodec.string(row['name']),
      nameNormalized: DatabaseValueCodec.string(row['name_normalized']),
      phone: DatabaseValueCodec.stringOrNull(row['phone']),
      roleHint: DatabaseValueCodec.stringOrNull(row['role_hint']),
      company: DatabaseValueCodec.stringOrNull(row['company']),
      notes: DatabaseValueCodec.stringOrNull(row['notes']),
      createdAt: DatabaseValueCodec.dateTime(row['created_at']),
      updatedAt: DatabaseValueCodec.dateTime(row['updated_at']),
    );
  }
}
import 'package:lifeflow_app/features/finance/domain/person.dart';

class PersonFailure implements Exception {
  const PersonFailure(this.message);
  final String message;
}

abstract interface class PersonRepository {
  Future<List<Person>> getPeople();
  Future<Person> getPerson(String id);
  Future<Person> savePerson(String id, PersonDraft draft);
  Future<void> deletePerson(String id);
}

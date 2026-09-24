class Person {
  const Person({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.birthDate,
  });
  final String id, name;
  final DateTime? birthDate;
  final DateTime createdAt, updatedAt;
}

class PersonDraft {
  const PersonDraft({required this.name, this.birthDate});
  final String name;
  final DateTime? birthDate;
}

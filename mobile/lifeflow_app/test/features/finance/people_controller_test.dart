import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeflow_app/features/finance/data/supabase_person_repository.dart';
import 'package:lifeflow_app/features/finance/domain/person.dart';
import 'package:lifeflow_app/features/finance/domain/person_repository.dart';
import 'package:lifeflow_app/features/finance/presentation/people_controller.dart';

void main() {
  test('cria, edita e remove pessoa', () async {
    final container = ProviderContainer(
      overrides: [personRepositoryProvider.overrideWithValue(_Fake())],
    );
    addTearDown(container.dispose);
    await container.read(peopleControllerProvider.future);
    final controller = container.read(peopleControllerProvider.notifier);

    final created = await controller.create(const PersonDraft(name: 'Ana'));
    expect(created.name, 'Ana');

    await controller.updatePerson(created.id, const PersonDraft(name: 'Ana Paula'));
    expect(
      container.read(peopleControllerProvider).value?.single.name,
      'Ana Paula',
    );

    await controller.delete(created.id);
    expect(container.read(peopleControllerProvider).value, isEmpty);
  });
}

class _Fake implements PersonRepository {
  Person? value;

  @override
  Future<List<Person>> getPeople() async => value == null ? [] : [value!];

  @override
  Future<Person> getPerson(String id) async => value!;

  @override
  Future<Person> savePerson(String id, PersonDraft draft) async =>
      value = Person(
        id: id,
        name: draft.name,
        birthDate: draft.birthDate,
        createdAt: DateTime.utc(2026, 9, 20),
        updatedAt: DateTime.utc(2026, 9, 20),
      );

  @override
  Future<void> deletePerson(String id) async => value = null;
}

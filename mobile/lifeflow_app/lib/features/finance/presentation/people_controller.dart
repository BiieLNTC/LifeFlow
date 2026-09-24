import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeflow_app/features/finance/data/supabase_person_repository.dart';
import 'package:lifeflow_app/features/finance/domain/person.dart';
import 'package:uuid/uuid.dart';

final peopleControllerProvider =
    AsyncNotifierProvider<PeopleController, List<Person>>(
      PeopleController.new,
    );

final personDetailsProvider = FutureProvider.family<Person, String>(
  (ref, id) => ref.watch(personRepositoryProvider).getPerson(id),
);

class PeopleController extends AsyncNotifier<List<Person>> {
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Person>> build() =>
      ref.watch(personRepositoryProvider).getPeople();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(personRepositoryProvider).getPeople(),
    );
  }

  Future<Person> create(PersonDraft draft) async {
    final person = await ref
        .read(personRepositoryProvider)
        .savePerson(_uuid.v7(), draft);
    state = AsyncData([person, ...?state.value]);
    return person;
  }

  Future<Person> updatePerson(String id, PersonDraft draft) async {
    final person = await ref
        .read(personRepositoryProvider)
        .savePerson(id, draft);
    state = AsyncData([
      for (final item in state.value ?? const <Person>[])
        if (item.id == id) person else item,
    ]);
    ref.invalidate(personDetailsProvider(id));
    return person;
  }

  Future<void> delete(String id) async {
    await ref.read(personRepositoryProvider).deletePerson(id);
    state = AsyncData(
      (state.value ?? const <Person>[]).where((p) => p.id != id).toList(),
    );
    ref.invalidate(personDetailsProvider(id));
  }
}

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class CachedRecords extends Table {
  TextColumn get userId => text()();
  TextColumn get entityType => text()();
  TextColumn get recordId => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get payloadJson => text()();
  TextColumn get syncStatus => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {userId, entityType, recordId};
}

class PendingMutations extends Table {
  TextColumn get mutationId => text()();
  TextColumn get userId => text()();
  TextColumn get entityType => text()();
  TextColumn get recordId => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get baseUpdatedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mutationId};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, entityType, recordId},
  ];
}

@DriftDatabase(tables: [CachedRecords, PendingMutations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationSupportDirectory();
  return NativeDatabase.createInBackground(
    File(path.join(directory.path, 'motora.sqlite')),
  );
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

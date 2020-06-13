import 'dart:async';
import 'package:sembast/sembast.dart';

Future<String> insert(Database database, StoreRef storeRef, Map value) async {
  Completer<String> completer = Completer();
  await database.transaction((txn) async {
    String key = await storeRef.add(txn, value);
    final record = storeRef.record(key);
    await record.update(txn, {'k': key});
    completer.complete(key);
  });
  return completer.future;
}

Future<void> update(Database database, StoreRef storeRef, Map value) async {
  final record = storeRef.record(value['k']);
  return record.update(database, value);
}

Future<void> delete(Database database, StoreRef storeRef, String key) {
  final record = storeRef.record(key);
  return record.delete(database);
}

Future<RecordSnapshot> get(Database database, StoreRef storeRef, String key) {
  return storeRef.findFirst(database,
      finder: Finder(filter: Filter.byKey(key)));
}

Future<List<RecordSnapshot>> find(Database database, StoreRef storeRef,
    {Finder finder}) {
  return storeRef.find(database, finder: finder);
}

Future<void> deleteFound(Database database, StoreRef storeRef, Finder finder) {
  return storeRef.delete(database, finder: finder);
}

Future<int> count(Database database, StoreRef storeRef, {Filter filter}) {
  return storeRef.count(database, filter: filter);
}

Future deleteStore(Database database, StoreRef storeRef) {
  return storeRef.drop(database);
}

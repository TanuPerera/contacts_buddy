// utils/database_helper.dart
import 'dart:async';
import 'dart:io';

import 'package:concats_buddy/models/contact_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  DatabaseHelper.internal();

  Future<Database> initDb() async {
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentDirectory.path, "contacts.db");
    var ourDb = await openDatabase(path, version: 1, onCreate: _onCreate);
    return ourDb;
  }

  void _onCreate(Database db, int version) async {
    await db.execute(
        "CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phoneNumber TEXT)");
  }

  Future<int> saveContact(Contact contact) async {
    var dbClient = await db;
    int res = await dbClient.insert("contacts", contact.toMap());
    return res;
  }

  Future<List<Contact>> getContacts() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM contacts');
    List<Contact> contacts = [];
    for (int i = 0; i < list.length; i++) {
      contacts.add(Contact.fromMap(list[i]));
    }
    return contacts;
  }

  Future<int> deleteContact(int id) async {
    var dbClient = await db;
    return await dbClient.delete("contacts", where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateContact(Contact contact) async {
    var dbClient = await db;
    return await dbClient.update("contacts", contact.toMap(),
        where: "id = ?", whereArgs: [contact.id]);
  }

  Future<List<Contact>> searchContacts(String query) async {
    var dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.rawQuery(
      'SELECT * FROM contacts WHERE name LIKE ? OR phoneNumber LIKE ?',
      ['%$query%', '%$query%'],
    );

    return List.generate(maps.length, (index) {
      return Contact.fromMap(maps[index]);
    });
  }
}

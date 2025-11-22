import 'package:isar/isar.dart';

part 'book.g.dart';

@collection
class Book {
  Id id = Isar.autoIncrement;

  late String title;

  late String filePath;

  int lastReadPage = 0;

  int? totalPages;

  late DateTime addedDate;

  DateTime? lastReadDate;
}

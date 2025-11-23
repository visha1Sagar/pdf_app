import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;

  late String bookPath;

  late int pageNumber;

  late String noteText;

  String? selectedText; // Optional: text that was highlighted when note was created

  late DateTime createdAt;

  DateTime? updatedAt;

  // Optional: position on page for visual indicators
  double? positionX;
  double? positionY;
}

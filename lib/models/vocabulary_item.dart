import 'package:isar/isar.dart';

part 'vocabulary_item.g.dart';

@collection
class VocabularyItem {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String word;

  late String definition;

  late DateTime timestamp;
}

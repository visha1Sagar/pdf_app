// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetNoteCollection on Isar {
  IsarCollection<Note> get notes => this.collection();
}

const NoteSchema = CollectionSchema(
  name: r'Note',
  id: 6284318083599466921,
  properties: {
    r'bookPath': PropertySchema(
      id: 0,
      name: r'bookPath',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'noteText': PropertySchema(
      id: 2,
      name: r'noteText',
      type: IsarType.string,
    ),
    r'pageNumber': PropertySchema(
      id: 3,
      name: r'pageNumber',
      type: IsarType.long,
    ),
    r'positionX': PropertySchema(
      id: 4,
      name: r'positionX',
      type: IsarType.double,
    ),
    r'positionY': PropertySchema(
      id: 5,
      name: r'positionY',
      type: IsarType.double,
    ),
    r'selectedText': PropertySchema(
      id: 6,
      name: r'selectedText',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 7,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _noteEstimateSize,
  serialize: _noteSerialize,
  deserialize: _noteDeserialize,
  deserializeProp: _noteDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _noteGetId,
  getLinks: _noteGetLinks,
  attach: _noteAttach,
  version: '3.1.0+1',
);

int _noteEstimateSize(
  Note object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bookPath.length * 3;
  bytesCount += 3 + object.noteText.length * 3;
  {
    final value = object.selectedText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _noteSerialize(
  Note object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.bookPath);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.noteText);
  writer.writeLong(offsets[3], object.pageNumber);
  writer.writeDouble(offsets[4], object.positionX);
  writer.writeDouble(offsets[5], object.positionY);
  writer.writeString(offsets[6], object.selectedText);
  writer.writeDateTime(offsets[7], object.updatedAt);
}

Note _noteDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Note();
  object.bookPath = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.noteText = reader.readString(offsets[2]);
  object.pageNumber = reader.readLong(offsets[3]);
  object.positionX = reader.readDoubleOrNull(offsets[4]);
  object.positionY = reader.readDoubleOrNull(offsets[5]);
  object.selectedText = reader.readStringOrNull(offsets[6]);
  object.updatedAt = reader.readDateTimeOrNull(offsets[7]);
  return object;
}

P _noteDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _noteGetId(Note object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _noteGetLinks(Note object) {
  return [];
}

void _noteAttach(IsarCollection<dynamic> col, Id id, Note object) {
  object.id = id;
}

extension NoteQueryWhereSort on QueryBuilder<Note, Note, QWhere> {
  QueryBuilder<Note, Note, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension NoteQueryWhere on QueryBuilder<Note, Note, QWhereClause> {
  QueryBuilder<Note, Note, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Note, Note, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Note, Note, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Note, Note, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension NoteQueryFilter on QueryBuilder<Note, Note, QFilterCondition> {
  QueryBuilder<Note, Note, QAfterFilterCondition> bookPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> bookPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bookPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> bookPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bookPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> bookPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bookPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> bookPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'bookPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> bookPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'bookPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> bookPathContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'bookPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> bookPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'bookPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> bookPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bookPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> bookPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'bookPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> noteTextEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> noteTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> noteTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> noteTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'noteText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> noteTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> noteTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> noteTextContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'noteText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> noteTextMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'noteText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> noteTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'noteText',
        value: '',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> noteTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'noteText',
        value: '',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> pageNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pageNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> pageNumberGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pageNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> pageNumberLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pageNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> pageNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pageNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionXIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'positionX',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionXIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'positionX',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionXEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'positionX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionXGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'positionX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionXLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'positionX',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionXBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'positionX',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionYIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'positionY',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionYIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'positionY',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionYEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'positionY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionYGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'positionY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionYLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'positionY',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> positionYBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'positionY',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'selectedText',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'selectedText',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'selectedText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'selectedText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'selectedText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'selectedText',
        value: '',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> selectedTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'selectedText',
        value: '',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'updatedAt',
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> updatedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Note, Note, QAfterFilterCondition> updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension NoteQueryObject on QueryBuilder<Note, Note, QFilterCondition> {}

extension NoteQueryLinks on QueryBuilder<Note, Note, QFilterCondition> {}

extension NoteQuerySortBy on QueryBuilder<Note, Note, QSortBy> {
  QueryBuilder<Note, Note, QAfterSortBy> sortByBookPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookPath', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByBookPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookPath', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByNoteText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteText', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByNoteTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteText', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByPageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageNumber', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByPageNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageNumber', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByPositionX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionX', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByPositionXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionX', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByPositionY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionY', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByPositionYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionY', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortBySelectedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedText', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortBySelectedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedText', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension NoteQuerySortThenBy on QueryBuilder<Note, Note, QSortThenBy> {
  QueryBuilder<Note, Note, QAfterSortBy> thenByBookPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookPath', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByBookPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bookPath', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByNoteText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteText', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByNoteTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'noteText', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByPageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageNumber', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByPageNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pageNumber', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByPositionX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionX', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByPositionXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionX', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByPositionY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionY', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByPositionYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionY', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenBySelectedText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedText', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenBySelectedTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'selectedText', Sort.desc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<Note, Note, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension NoteQueryWhereDistinct on QueryBuilder<Note, Note, QDistinct> {
  QueryBuilder<Note, Note, QDistinct> distinctByBookPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bookPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Note, Note, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Note, Note, QDistinct> distinctByNoteText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'noteText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Note, Note, QDistinct> distinctByPageNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pageNumber');
    });
  }

  QueryBuilder<Note, Note, QDistinct> distinctByPositionX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'positionX');
    });
  }

  QueryBuilder<Note, Note, QDistinct> distinctByPositionY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'positionY');
    });
  }

  QueryBuilder<Note, Note, QDistinct> distinctBySelectedText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'selectedText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Note, Note, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension NoteQueryProperty on QueryBuilder<Note, Note, QQueryProperty> {
  QueryBuilder<Note, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Note, String, QQueryOperations> bookPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bookPath');
    });
  }

  QueryBuilder<Note, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Note, String, QQueryOperations> noteTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'noteText');
    });
  }

  QueryBuilder<Note, int, QQueryOperations> pageNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pageNumber');
    });
  }

  QueryBuilder<Note, double?, QQueryOperations> positionXProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'positionX');
    });
  }

  QueryBuilder<Note, double?, QQueryOperations> positionYProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'positionY');
    });
  }

  QueryBuilder<Note, String?, QQueryOperations> selectedTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'selectedText');
    });
  }

  QueryBuilder<Note, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

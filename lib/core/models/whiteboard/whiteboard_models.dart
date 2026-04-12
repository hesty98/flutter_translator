import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'whiteboard_models.g.dart';

enum WhiteboardTool { pointer, rectangle, roundedRectangle, entity, connector }

enum WhiteboardItemType { rectangle, roundedRectangle, entity, connector }

enum SqlDialect { postgres, mysql, sqlite, sqlServer }

enum ConnectorLineStyle { straight, curved, orthogonal, rounded }

enum ConnectorFamily { plain, database }

enum ConnectorRelationKind {
  none,
  oneToOne,
  zeroToOne,
  oneToMany,
  zeroToMany,
  manyToMany,
}

enum TextHorizontalAlign { left, center, right }

enum TextVerticalAlign { top, center, bottom }

enum ConnectorAnchor { top, right, bottom, left }

const _postgresDataTypes = <String>[
  'smallint',
  'integer',
  'bigint',
  'numeric',
  'real',
  'double precision',
  'varchar',
  'text',
  'boolean',
  'date',
  'timestamp',
  'uuid',
  'jsonb',
];

const _mysqlDataTypes = <String>[
  'tinyint',
  'smallint',
  'int',
  'bigint',
  'decimal',
  'float',
  'double',
  'varchar(255)',
  'text',
  'boolean',
  'date',
  'datetime',
  'timestamp',
  'json',
];

const _sqliteDataTypes = <String>['integer', 'real', 'text', 'blob', 'numeric'];

const _sqlServerDataTypes = <String>[
  'bit',
  'tinyint',
  'smallint',
  'int',
  'bigint',
  'decimal',
  'float',
  'nvarchar(255)',
  'varchar(255)',
  'text',
  'date',
  'datetime2',
  'uniqueidentifier',
];

List<String> sqlDataTypesFor(SqlDialect dialect) {
  return switch (dialect) {
    SqlDialect.postgres => _postgresDataTypes,
    SqlDialect.mysql => _mysqlDataTypes,
    SqlDialect.sqlite => _sqliteDataTypes,
    SqlDialect.sqlServer => _sqlServerDataTypes,
  };
}

String defaultSqlDataTypeFor(SqlDialect dialect) =>
    sqlDataTypesFor(dialect).first;

bool isValidSqlDataType(SqlDialect dialect, String value) {
  return sqlDataTypesFor(dialect).contains(value);
}

class OffsetJsonConverter
    implements JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetJsonConverter();

  @override
  Offset fromJson(Map<String, dynamic> json) {
    return Offset(
      (json['dx'] as num?)?.toDouble() ?? 0,
      (json['dy'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson(Offset object) {
    return {'dx': object.dx, 'dy': object.dy};
  }
}

class RectJsonConverter implements JsonConverter<Rect, Map<String, dynamic>> {
  const RectJsonConverter();

  @override
  Rect fromJson(Map<String, dynamic> json) {
    return Rect.fromLTWH(
      (json['left'] as num?)?.toDouble() ?? 0,
      (json['top'] as num?)?.toDouble() ?? 0,
      (json['width'] as num?)?.toDouble() ?? 0,
      (json['height'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson(Rect object) {
    return {
      'left': object.left,
      'top': object.top,
      'width': object.width,
      'height': object.height,
    };
  }
}

class OffsetListJsonConverter
    implements JsonConverter<List<Offset>, List<dynamic>> {
  const OffsetListJsonConverter();

  @override
  List<Offset> fromJson(List<dynamic> json) {
    return json
        .map((point) {
          final map = (point as Map).cast<String, dynamic>();
          return Offset(
            (map['dx'] as num?)?.toDouble() ?? 0,
            (map['dy'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList(growable: false);
  }

  @override
  List<dynamic> toJson(List<Offset> object) {
    return object
        .map((point) => {'dx': point.dx, 'dy': point.dy})
        .toList(growable: false);
  }
}

@JsonSerializable(explicitToJson: true)
class WhiteboardDocument {
  const WhiteboardDocument({
    required this.id,
    required this.name,
    required this.sqlDialect,
    @OffsetJsonConverter() required this.viewportOffset,
    required this.zoom,
    required this.items,
  });

  factory WhiteboardDocument.initial() => const WhiteboardDocument(
    id: 'main-board',
    name: 'Whiteboard',
    sqlDialect: SqlDialect.postgres,
    viewportOffset: Offset(-120, -120),
    zoom: 1,
    items: <WhiteboardItem>[],
  );

  factory WhiteboardDocument.fromJson(String source) =>
      WhiteboardDocument.fromMap(jsonDecode(source) as Map<String, dynamic>);

  factory WhiteboardDocument.fromJsonMap(Map<String, dynamic> json) =>
      _$WhiteboardDocumentFromJson(json);

  factory WhiteboardDocument.fromMap(Map<String, dynamic> json) =>
      WhiteboardDocument.fromJsonMap(json);

  final String id;
  final String name;
  final SqlDialect sqlDialect;
  @OffsetJsonConverter()
  final Offset viewportOffset;
  final double zoom;
  final List<WhiteboardItem> items;

  WhiteboardDocument copyWith({
    String? id,
    String? name,
    SqlDialect? sqlDialect,
    Offset? viewportOffset,
    double? zoom,
    List<WhiteboardItem>? items,
  }) {
    return WhiteboardDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      sqlDialect: sqlDialect ?? this.sqlDialect,
      viewportOffset: viewportOffset ?? this.viewportOffset,
      zoom: zoom ?? this.zoom,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() => _$WhiteboardDocumentToJson(this);

  Map<String, dynamic> toJsonMap() => _$WhiteboardDocumentToJson(this);

  String toJson() => jsonEncode(toMap());
}

class WhiteboardItem {
  const WhiteboardItem({
    required this.id,
    required this.type,
    @RectJsonConverter() required this.rect,
    required this.style,
    required this.data,
  });

  factory WhiteboardItem.fromMap(Map<String, dynamic> json) {
    final type = WhiteboardItemType.values.byName(
      json['type'] as String? ?? WhiteboardItemType.rectangle.name,
    );
    return WhiteboardItem(
      id: json['id'] as String? ?? '',
      type: type,
      rect: const RectJsonConverter().fromJson(
        (json['rect'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
      style: WhiteboardStyle.fromJson(
        (json['style'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
      data: WhiteboardItemData.fromMap(
        type,
        (json['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
    );
  }

  factory WhiteboardItem.fromJson(Map<String, dynamic> json) =>
      WhiteboardItem.fromMap(json);

  final String id;
  final WhiteboardItemType type;
  @RectJsonConverter()
  final Rect rect;
  final WhiteboardStyle style;
  final WhiteboardItemData data;

  bool get isConnector => type == WhiteboardItemType.connector;
  bool get isEntity => type == WhiteboardItemType.entity;
  bool get isShape => !isConnector && !isEntity;

  ShapeItemData? get shapeData =>
      data is ShapeItemData ? data as ShapeItemData : null;
  EntityItemData? get entityData =>
      data is EntityItemData ? data as EntityItemData : null;
  ConnectorItemData? get connectorData =>
      data is ConnectorItemData ? data as ConnectorItemData : null;

  String get text => switch (data) {
    ShapeItemData(:final text) => text,
    EntityItemData(:final title) => title,
    ConnectorItemData() => '',
    _ => '',
  };

  List<EntityColumn> get columns =>
      entityData?.columns ?? const <EntityColumn>[];

  List<Offset> get points => connectorData?.points ?? const <Offset>[];

  ConnectorLineStyle get connectorStyle =>
      connectorData?.style ?? ConnectorLineStyle.straight;
  ConnectorFamily get connectorFamily =>
      connectorData?.family ?? ConnectorFamily.plain;
  ConnectorRelationKind get connectorRelationKind =>
      connectorData?.relationKind ?? ConnectorRelationKind.none;

  WhiteboardItem copyWith({
    String? id,
    WhiteboardItemType? type,
    Rect? rect,
    WhiteboardStyle? style,
    WhiteboardItemData? data,
  }) {
    return WhiteboardItem(
      id: id ?? this.id,
      type: type ?? this.type,
      rect: rect ?? this.rect,
      style: style ?? this.style,
      data: data ?? this.data,
    );
  }

  WhiteboardItem copyWithText(String value) {
    if (shapeData case final shapeData?) {
      return copyWith(data: shapeData.copyWith(text: value));
    }
    if (entityData case final entityData?) {
      return copyWith(data: entityData.copyWith(title: value));
    }
    return this;
  }

  WhiteboardItem copyWithColumns(List<EntityColumn> value) {
    if (entityData case final entityData?) {
      return copyWith(data: entityData.copyWith(columns: value));
    }
    return this;
  }

  WhiteboardItem copyWithConnector({
    List<Offset>? points,
    ConnectorLineStyle? style,
    ConnectorFamily? family,
    ConnectorRelationKind? relationKind,
    String? sourceItemId,
    String? targetItemId,
    ConnectorAnchor? sourceAnchor,
    ConnectorAnchor? targetAnchor,
  }) {
    if (connectorData case final connectorData?) {
      return copyWith(
        data: connectorData.copyWith(
          points: points ?? connectorData.points,
          style: style ?? connectorData.style,
          family: family ?? connectorData.family,
          relationKind: relationKind ?? connectorData.relationKind,
          sourceItemId: sourceItemId ?? connectorData.sourceItemId,
          targetItemId: targetItemId ?? connectorData.targetItemId,
          sourceAnchor: sourceAnchor ?? connectorData.sourceAnchor,
          targetAnchor: targetAnchor ?? connectorData.targetAnchor,
        ),
      );
    }
    return this;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'type': type.name,
    'rect': const RectJsonConverter().toJson(rect),
    'style': style.toJson(),
    'data': data.toJson(),
  };

  Map<String, dynamic> toJson() => toMap();
}

abstract class WhiteboardItemData {
  const WhiteboardItemData();

  factory WhiteboardItemData.fromMap(
    WhiteboardItemType type,
    Map<String, dynamic> json,
  ) {
    return switch (type) {
      WhiteboardItemType.entity => EntityItemData.fromJson(json),
      WhiteboardItemType.connector => ConnectorItemData.fromJson(json),
      WhiteboardItemType.rectangle ||
      WhiteboardItemType.roundedRectangle => ShapeItemData.fromJson(json),
    };
  }

  Map<String, dynamic> toJson();
}

@JsonSerializable()
class ShapeItemData extends WhiteboardItemData {
  const ShapeItemData({required this.text});

  factory ShapeItemData.fromMap(Map<String, dynamic> json) =>
      _$ShapeItemDataFromJson(json);

  factory ShapeItemData.fromJson(Map<String, dynamic> json) =>
      _$ShapeItemDataFromJson(json);

  final String text;

  ShapeItemData copyWith({String? text}) {
    return ShapeItemData(text: text ?? this.text);
  }

  @override
  Map<String, dynamic> toJson() => _$ShapeItemDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EntityItemData extends WhiteboardItemData {
  const EntityItemData({required this.title, required this.columns});

  factory EntityItemData.fromMap(Map<String, dynamic> json) =>
      _$EntityItemDataFromJson(json);

  factory EntityItemData.fromJson(Map<String, dynamic> json) =>
      _$EntityItemDataFromJson(json);

  final String title;
  final List<EntityColumn> columns;

  EntityItemData copyWith({String? title, List<EntityColumn>? columns}) {
    return EntityItemData(
      title: title ?? this.title,
      columns: columns ?? this.columns,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$EntityItemDataToJson(this);
}

@JsonSerializable()
class ConnectorItemData extends WhiteboardItemData {
  const ConnectorItemData({
    @OffsetListJsonConverter() required this.points,
    this.style = ConnectorLineStyle.straight,
    this.family = ConnectorFamily.plain,
    this.relationKind = ConnectorRelationKind.none,
    this.sourceItemId,
    this.targetItemId,
    this.sourceAnchor,
    this.targetAnchor,
  });

  factory ConnectorItemData.fromMap(Map<String, dynamic> json) =>
      _$ConnectorItemDataFromJson(json);

  factory ConnectorItemData.fromJson(Map<String, dynamic> json) =>
      _$ConnectorItemDataFromJson(json);

  @OffsetListJsonConverter()
  final List<Offset> points;
  final ConnectorLineStyle style;
  final ConnectorFamily family;
  final ConnectorRelationKind relationKind;
  final String? sourceItemId;
  final String? targetItemId;
  final ConnectorAnchor? sourceAnchor;
  final ConnectorAnchor? targetAnchor;

  ConnectorItemData copyWith({
    List<Offset>? points,
    ConnectorLineStyle? style,
    ConnectorFamily? family,
    ConnectorRelationKind? relationKind,
    String? sourceItemId,
    bool clearSourceItemId = false,
    String? targetItemId,
    bool clearTargetItemId = false,
    ConnectorAnchor? sourceAnchor,
    bool clearSourceAnchor = false,
    ConnectorAnchor? targetAnchor,
    bool clearTargetAnchor = false,
  }) {
    return ConnectorItemData(
      points: points ?? this.points,
      style: style ?? this.style,
      family: family ?? this.family,
      relationKind: relationKind ?? this.relationKind,
      sourceItemId: clearSourceItemId
          ? null
          : sourceItemId ?? this.sourceItemId,
      targetItemId: clearTargetItemId
          ? null
          : targetItemId ?? this.targetItemId,
      sourceAnchor: clearSourceAnchor
          ? null
          : sourceAnchor ?? this.sourceAnchor,
      targetAnchor: clearTargetAnchor
          ? null
          : targetAnchor ?? this.targetAnchor,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$ConnectorItemDataToJson(this);
}

({String? source, String? target}) connectorEndpointLabels(
  ConnectorFamily family,
  ConnectorRelationKind relationKind,
) {
  if (family == ConnectorFamily.plain) {
    return (source: null, target: null);
  }
  return switch (relationKind) {
    ConnectorRelationKind.none => (source: null, target: null),
    ConnectorRelationKind.oneToOne => (source: '1', target: '1'),
    ConnectorRelationKind.zeroToOne => (source: '0..1', target: '1'),
    ConnectorRelationKind.oneToMany => (source: '1', target: 'N'),
    ConnectorRelationKind.zeroToMany => (source: '0..1', target: 'N'),
    ConnectorRelationKind.manyToMany => (source: 'N', target: 'M'),
  };
}

@JsonSerializable()
class WhiteboardStyle {
  const WhiteboardStyle({
    required this.fillColor,
    required this.strokeColor,
    required this.textColor,
    required this.textSize,
    this.textHorizontalAlign = TextHorizontalAlign.center,
    this.textVerticalAlign = TextVerticalAlign.center,
  });

  factory WhiteboardStyle.defaultsFor(WhiteboardItemType type) {
    switch (type) {
      case WhiteboardItemType.roundedRectangle:
        return const WhiteboardStyle(
          fillColor: 0xFFFEE7C8,
          strokeColor: 0xFFCC8A2E,
          textColor: 0xFF33230E,
          textSize: 15,
          textHorizontalAlign: TextHorizontalAlign.center,
          textVerticalAlign: TextVerticalAlign.center,
        );
      case WhiteboardItemType.entity:
        return const WhiteboardStyle(
          fillColor: 0xFFDDEBFF,
          strokeColor: 0xFF3D6FB4,
          textColor: 0xFF11233C,
          textSize: 15,
          textHorizontalAlign: TextHorizontalAlign.left,
          textVerticalAlign: TextVerticalAlign.top,
        );
      case WhiteboardItemType.connector:
        return const WhiteboardStyle(
          fillColor: 0x00000000,
          strokeColor: 0xFF334155,
          textColor: 0xFF1E293B,
          textSize: 14,
          textHorizontalAlign: TextHorizontalAlign.center,
          textVerticalAlign: TextVerticalAlign.center,
        );
      case WhiteboardItemType.rectangle:
        return const WhiteboardStyle(
          fillColor: 0xFFE2F6E9,
          strokeColor: 0xFF2F8A56,
          textColor: 0xFF0F2B1B,
          textSize: 15,
          textHorizontalAlign: TextHorizontalAlign.center,
          textVerticalAlign: TextVerticalAlign.center,
        );
    }
  }

  factory WhiteboardStyle.fromMap(Map<String, dynamic> json) =>
      _$WhiteboardStyleFromJson(json);

  factory WhiteboardStyle.fromJson(Map<String, dynamic> json) =>
      _$WhiteboardStyleFromJson(json);

  final int fillColor;
  final int strokeColor;
  final int textColor;
  final double textSize;
  final TextHorizontalAlign textHorizontalAlign;
  final TextVerticalAlign textVerticalAlign;

  WhiteboardStyle copyWith({
    int? fillColor,
    int? strokeColor,
    int? textColor,
    double? textSize,
    TextHorizontalAlign? textHorizontalAlign,
    TextVerticalAlign? textVerticalAlign,
  }) {
    return WhiteboardStyle(
      fillColor: fillColor ?? this.fillColor,
      strokeColor: strokeColor ?? this.strokeColor,
      textColor: textColor ?? this.textColor,
      textSize: textSize ?? this.textSize,
      textHorizontalAlign: textHorizontalAlign ?? this.textHorizontalAlign,
      textVerticalAlign: textVerticalAlign ?? this.textVerticalAlign,
    );
  }

  Map<String, dynamic> toMap() => _$WhiteboardStyleToJson(this);

  Map<String, dynamic> toJson() => _$WhiteboardStyleToJson(this);

  Color get fill => Color(fillColor);
  Color get stroke => Color(strokeColor);
  Color get text => Color(textColor);
}

@JsonSerializable()
class EntityColumn {
  const EntityColumn({
    required this.id,
    required this.name,
    required this.dataType,
    required this.nullable,
    required this.isPrimaryKey,
    required this.isForeignKey,
  });

  factory EntityColumn.fromMap(Map<String, dynamic> json) =>
      _$EntityColumnFromJson(json);

  factory EntityColumn.fromJson(Map<String, dynamic> json) =>
      _$EntityColumnFromJson(json);

  final String id;
  final String name;
  final String dataType;
  final bool nullable;
  final bool isPrimaryKey;
  final bool isForeignKey;

  EntityColumn copyWith({
    String? id,
    String? name,
    String? dataType,
    bool? nullable,
    bool? isPrimaryKey,
    bool? isForeignKey,
  }) {
    return EntityColumn(
      id: id ?? this.id,
      name: name ?? this.name,
      dataType: dataType ?? this.dataType,
      nullable: nullable ?? this.nullable,
      isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
      isForeignKey: isForeignKey ?? this.isForeignKey,
    );
  }

  Map<String, dynamic> toMap() => _$EntityColumnToJson(this);

  Map<String, dynamic> toJson() => _$EntityColumnToJson(this);
}

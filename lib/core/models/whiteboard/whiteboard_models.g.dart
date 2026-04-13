// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whiteboard_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WhiteboardDocument _$WhiteboardDocumentFromJson(Map<String, dynamic> json) =>
    WhiteboardDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      sqlDialect: $enumDecode(_$SqlDialectEnumMap, json['sqlDialect']),
      viewportOffset: const OffsetJsonConverter().fromJson(
        json['viewportOffset'] as Map<String, dynamic>,
      ),
      zoom: (json['zoom'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((e) => WhiteboardItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WhiteboardDocumentToJson(
  WhiteboardDocument instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'sqlDialect': _$SqlDialectEnumMap[instance.sqlDialect]!,
  'viewportOffset': const OffsetJsonConverter().toJson(instance.viewportOffset),
  'zoom': instance.zoom,
  'items': instance.items.map((e) => e.toJson()).toList(),
};

const _$SqlDialectEnumMap = {
  SqlDialect.postgres: 'postgres',
  SqlDialect.mysql: 'mysql',
  SqlDialect.sqlite: 'sqlite',
  SqlDialect.sqlServer: 'sqlServer',
};

ShapeItemData _$ShapeItemDataFromJson(Map<String, dynamic> json) =>
    ShapeItemData(text: json['text'] as String);

Map<String, dynamic> _$ShapeItemDataToJson(ShapeItemData instance) =>
    <String, dynamic>{'text': instance.text};

EntityItemData _$EntityItemDataFromJson(Map<String, dynamic> json) =>
    EntityItemData(
      title: json['title'] as String,
      columns: (json['columns'] as List<dynamic>)
          .map((e) => EntityColumn.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EntityItemDataToJson(EntityItemData instance) =>
    <String, dynamic>{
      'title': instance.title,
      'columns': instance.columns.map((e) => e.toJson()).toList(),
    };

ConnectorItemData _$ConnectorItemDataFromJson(Map<String, dynamic> json) =>
    ConnectorItemData(
      points: const OffsetListJsonConverter().fromJson(json['points'] as List),
      style:
          $enumDecodeNullable(_$ConnectorLineStyleEnumMap, json['style']) ??
          ConnectorLineStyle.straight,
      family:
          $enumDecodeNullable(_$ConnectorFamilyEnumMap, json['family']) ??
          ConnectorFamily.plain,
      relationKind:
          $enumDecodeNullable(
            _$ConnectorRelationKindEnumMap,
            json['relationKind'],
          ) ??
          ConnectorRelationKind.none,
      sourceItemId: json['sourceItemId'] as String?,
      targetItemId: json['targetItemId'] as String?,
      sourceAnchor: $enumDecodeNullable(
        _$ConnectorAnchorEnumMap,
        json['sourceAnchor'],
      ),
      targetAnchor: $enumDecodeNullable(
        _$ConnectorAnchorEnumMap,
        json['targetAnchor'],
      ),
    );

Map<String, dynamic> _$ConnectorItemDataToJson(ConnectorItemData instance) =>
    <String, dynamic>{
      'points': const OffsetListJsonConverter().toJson(instance.points),
      'style': _$ConnectorLineStyleEnumMap[instance.style]!,
      'family': _$ConnectorFamilyEnumMap[instance.family]!,
      'relationKind': _$ConnectorRelationKindEnumMap[instance.relationKind]!,
      'sourceItemId': instance.sourceItemId,
      'targetItemId': instance.targetItemId,
      'sourceAnchor': _$ConnectorAnchorEnumMap[instance.sourceAnchor],
      'targetAnchor': _$ConnectorAnchorEnumMap[instance.targetAnchor],
    };

const _$ConnectorLineStyleEnumMap = {
  ConnectorLineStyle.straight: 'straight',
  ConnectorLineStyle.curved: 'curved',
  ConnectorLineStyle.orthogonal: 'orthogonal',
  ConnectorLineStyle.rounded: 'rounded',
};

const _$ConnectorFamilyEnumMap = {
  ConnectorFamily.plain: 'plain',
  ConnectorFamily.database: 'database',
};

const _$ConnectorRelationKindEnumMap = {
  ConnectorRelationKind.none: 'none',
  ConnectorRelationKind.oneToOne: 'oneToOne',
  ConnectorRelationKind.zeroToOne: 'zeroToOne',
  ConnectorRelationKind.oneToMany: 'oneToMany',
  ConnectorRelationKind.zeroToMany: 'zeroToMany',
  ConnectorRelationKind.manyToMany: 'manyToMany',
};

const _$ConnectorAnchorEnumMap = {
  ConnectorAnchor.top: 'top',
  ConnectorAnchor.right: 'right',
  ConnectorAnchor.bottom: 'bottom',
  ConnectorAnchor.left: 'left',
};

WhiteboardStyle _$WhiteboardStyleFromJson(Map<String, dynamic> json) =>
    WhiteboardStyle(
      fillColor: (json['fillColor'] as num).toInt(),
      strokeColor: (json['strokeColor'] as num).toInt(),
      textColor: (json['textColor'] as num).toInt(),
      textSize: (json['textSize'] as num).toDouble(),
      textHorizontalAlign:
          $enumDecodeNullable(
            _$TextHorizontalAlignEnumMap,
            json['textHorizontalAlign'],
          ) ??
          TextHorizontalAlign.center,
      textVerticalAlign:
          $enumDecodeNullable(
            _$TextVerticalAlignEnumMap,
            json['textVerticalAlign'],
          ) ??
          TextVerticalAlign.center,
    );

Map<String, dynamic> _$WhiteboardStyleToJson(
  WhiteboardStyle instance,
) => <String, dynamic>{
  'fillColor': instance.fillColor,
  'strokeColor': instance.strokeColor,
  'textColor': instance.textColor,
  'textSize': instance.textSize,
  'textHorizontalAlign':
      _$TextHorizontalAlignEnumMap[instance.textHorizontalAlign]!,
  'textVerticalAlign': _$TextVerticalAlignEnumMap[instance.textVerticalAlign]!,
};

const _$TextHorizontalAlignEnumMap = {
  TextHorizontalAlign.left: 'left',
  TextHorizontalAlign.center: 'center',
  TextHorizontalAlign.right: 'right',
};

const _$TextVerticalAlignEnumMap = {
  TextVerticalAlign.top: 'top',
  TextVerticalAlign.center: 'center',
  TextVerticalAlign.bottom: 'bottom',
};

EntityColumn _$EntityColumnFromJson(Map<String, dynamic> json) => EntityColumn(
  id: json['id'] as String,
  name: json['name'] as String,
  dataType: json['dataType'] as String,
  nullable: json['nullable'] as bool,
  isPrimaryKey: json['isPrimaryKey'] as bool,
  isForeignKey: json['isForeignKey'] as bool,
);

Map<String, dynamic> _$EntityColumnToJson(EntityColumn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'dataType': instance.dataType,
      'nullable': instance.nullable,
      'isPrimaryKey': instance.isPrimaryKey,
      'isForeignKey': instance.isForeignKey,
    };

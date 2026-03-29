/// SQLite projection for [accounts] (v1 schema).
final class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.nature,
    this.parentId,
    required this.isDefault,
    required this.isActive,
    required this.createdAtIso,
    this.standardClassification,
    this.customClassificationName,
    this.customClassificationNature,
  });

  final String id;
  final String name;
  final String nature;
  final String? parentId;
  final bool isDefault;
  final bool isActive;
  final String createdAtIso;
  final String? standardClassification;
  final String? customClassificationName;
  final String? customClassificationNature;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'nature': nature,
        'parent_id': parentId,
        'is_default': isDefault ? 1 : 0,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAtIso,
        'standard_classification': standardClassification,
        'custom_classification_name': customClassificationName,
        'custom_classification_nature': customClassificationNature,
      };

  factory AccountModel.fromMap(Map<String, Object?> map) {
    return AccountModel(
      id: map['id']! as String,
      name: map['name']! as String,
      nature: map['nature']! as String,
      parentId: map['parent_id'] as String?,
      isDefault: (map['is_default'] as int) == 1,
      isActive: (map['is_active'] as int) == 1,
      createdAtIso: map['created_at']! as String,
      standardClassification: map['standard_classification'] as String?,
      customClassificationName: map['custom_classification_name'] as String?,
      customClassificationNature:
          map['custom_classification_nature'] as String?,
    );
  }
}

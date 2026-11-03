import 'package:equatable/equatable.dart';

/// What kind of device an asset is. The first letters of its code come
/// from here (`LAP-0007` is a laptop). Stored as text in `assets.category`.
enum AssetCategory {
  laptop('LAP'),
  desktop('DSK'),
  monitor('MON'),
  printer('PRT'),
  phone('PHN'),
  network('NET'),
  other('OTH');

  const AssetCategory(this.codePrefix);
  final String codePrefix;

  static AssetCategory fromValue(String? value) => AssetCategory.values
      .firstWhere((c) => c.name == value, orElse: () => AssetCategory.other);
}

/// Where an asset is in its life. Stored as `active`, `in_repair`,
/// `storage` or `retired`.
enum AssetStatus {
  active('active'),
  inRepair('in_repair'),
  storage('storage'),
  retired('retired');

  const AssetStatus(this.value);
  final String value;

  static AssetStatus fromValue(String? value) => AssetStatus.values
      .firstWhere((s) => s.value == value, orElse: () => AssetStatus.active);
}

/// One physical company device with a QR sticker. Pure Dart.
class Asset extends Equatable {
  const Asset({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.status,
    this.brand = '',
    this.model = '',
    this.serial = '',
    this.siteId,
    this.locationId,
    this.assignedTo = '',
    this.purchaseDate,
    this.warrantyUntil,
    this.notes = '',
  });

  /// Empty id and code mean "not saved yet": the repository fills them in.
  const Asset.draft({
    this.name = '',
    this.category = AssetCategory.laptop,
    this.status = AssetStatus.active,
    this.brand = '',
    this.model = '',
    this.serial = '',
    this.siteId,
    this.locationId,
    this.assignedTo = '',
    this.purchaseDate,
    this.warrantyUntil,
    this.notes = '',
  }) : id = '',
       code = '';

  final String id;
  final String code;
  final String name;
  final AssetCategory category;
  final AssetStatus status;
  final String brand;
  final String model;
  final String serial;
  final String? siteId;
  final String? locationId;
  final String assignedTo;
  final DateTime? purchaseDate;
  final DateTime? warrantyUntil;
  final String notes;

  bool get isNew => id.isEmpty;

  bool get underWarranty =>
      warrantyUntil != null && warrantyUntil!.isAfter(DateTime.now());

  Asset copyWith({
    String? name,
    AssetCategory? category,
    AssetStatus? status,
    String? brand,
    String? model,
    String? serial,
    String? siteId,
    String? locationId,
    String? assignedTo,
    DateTime? purchaseDate,
    DateTime? warrantyUntil,
    String? notes,
  }) {
    return Asset(
      id: id,
      code: code,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serial: serial ?? this.serial,
      siteId: siteId ?? this.siteId,
      locationId: locationId ?? this.locationId,
      assignedTo: assignedTo ?? this.assignedTo,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyUntil: warrantyUntil ?? this.warrantyUntil,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id, code, name, category, status, brand, model, serial, siteId,
    locationId, assignedTo, purchaseDate, warrantyUntil, notes,
  ];
}

/// A building or branch. Assets live in locations inside a site.
class Site extends Equatable {
  const Site({required this.id, required this.name, this.city = ''});

  final String id;
  final String name;
  final String city;

  @override
  List<Object?> get props => [id, name, city];
}

/// A room, floor or cabinet inside a [Site].
class Location extends Equatable {
  const Location({required this.id, required this.siteId, required this.name});

  final String id;
  final String siteId;
  final String name;

  @override
  List<Object?> get props => [id, siteId, name];
}

/// What the asset list is filtered by.
class AssetQuery extends Equatable {
  const AssetQuery({this.text = '', this.status, this.category, this.siteId});

  final String text;
  final AssetStatus? status;
  final AssetCategory? category;
  final String? siteId;

  AssetQuery copyWith({
    String? text,
    AssetStatus? status,
    AssetCategory? category,
    String? siteId,
    bool clearStatus = false,
    bool clearCategory = false,
    bool clearSite = false,
  }) {
    return AssetQuery(
      text: text ?? this.text,
      status: clearStatus ? null : (status ?? this.status),
      category: clearCategory ? null : (category ?? this.category),
      siteId: clearSite ? null : (siteId ?? this.siteId),
    );
  }

  bool get hasFilters => status != null || category != null || siteId != null;

  @override
  List<Object?> get props => [text, status, category, siteId];
}

/// One page of the infinite-scrolling asset list.
class AssetPage {
  const AssetPage({required this.items, required this.hasMore});

  final List<Asset> items;
  final bool hasMore;
}

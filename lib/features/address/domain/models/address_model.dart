enum AddressType { home, office, other }

class AddressModel {
  final String id;
  final String houseNumber;
  final String building;
  final String area;
  final String? landmark;
  final String city;
  final String state;
  final String pinCode;
  final AddressType type;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.houseNumber,
    required this.building,
    required this.area,
    this.landmark,
    required this.city,
    required this.state,
    required this.pinCode,
    this.type = AddressType.home,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  String get shortLine => '$houseNumber, $building, $area';
  String get fullLine => '$houseNumber, $building, $area${landmark != null && landmark!.isNotEmpty ? ', $landmark' : ''}, $city, $state $pinCode';

  AddressModel copyWith({bool? isDefault}) => AddressModel(
        id: id,
        houseNumber: houseNumber,
        building: building,
        area: area,
        landmark: landmark,
        city: city,
        state: state,
        pinCode: pinCode,
        type: type,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault ?? this.isDefault,
      );

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'].toString(),
      houseNumber: json['house_number'] as String? ?? '',
      building: json['building'] as String? ?? '',
      area: json['area'] as String? ?? '',
      landmark: json['landmark'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pinCode: json['pin_code'] as String? ?? '',
      type: AddressType.values.byName(json['type'] as String? ?? 'home'),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'house_number': houseNumber,
        'building': building,
        'area': area,
        'landmark': landmark,
        'city': city,
        'state': state,
        'pin_code': pinCode,
        'type': type.name,
        'latitude': latitude,
        'longitude': longitude,
        'is_default': isDefault,
      };
}

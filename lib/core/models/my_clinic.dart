/// "Nơi khám của tôi": the user's own clinic/hospital profile (Phase 19, B9).
/// Stored locally only (see `MyClinicService`).
class MyClinic {
  final String name;
  final String doctor;
  final String phone;
  final String address;

  const MyClinic({
    this.name = '',
    this.doctor = '',
    this.phone = '',
    this.address = '',
  });

  /// Builds a profile with every field trimmed.
  factory MyClinic.trimmed({
    String name = '',
    String doctor = '',
    String phone = '',
    String address = '',
  }) => MyClinic(
    name: name.trim(),
    doctor: doctor.trim(),
    phone: phone.trim(),
    address: address.trim(),
  );

  static const MyClinic empty = MyClinic();

  bool get isEmpty =>
      name.isEmpty && doctor.isEmpty && phone.isEmpty && address.isEmpty;

  /// Digits in [phone].
  String get phoneDigits => phone.replaceAll(RegExp(r'[^0-9]'), '');

  /// A phone number worth dialling: at least 3 digits.
  bool get hasPhone => phoneDigits.length >= 3;

  /// Maps search text: the address, otherwise the name, otherwise null.
  String? get mapsQuery {
    if (address.isNotEmpty) return address;
    if (name.isNotEmpty) return name;
    return null;
  }

  Map<String, String> toJson() => {
    'name': name,
    'doctor': doctor,
    'phone': phone,
    'address': address,
  };

  /// Never throws: unknown or non-string values become empty.
  factory MyClinic.fromJson(Object? json) {
    if (json is! Map) return empty;
    String field(String key) {
      final value = json[key];
      return value is String ? value.trim() : '';
    }

    return MyClinic(
      name: field('name'),
      doctor: field('doctor'),
      phone: field('phone'),
      address: field('address'),
    );
  }

  MyClinic copyWith({
    String? name,
    String? doctor,
    String? phone,
    String? address,
  }) => MyClinic.trimmed(
    name: name ?? this.name,
    doctor: doctor ?? this.doctor,
    phone: phone ?? this.phone,
    address: address ?? this.address,
  );

  @override
  bool operator ==(Object other) =>
      other is MyClinic &&
      other.name == name &&
      other.doctor == doctor &&
      other.phone == phone &&
      other.address == address;

  @override
  int get hashCode => Object.hash(name, doctor, phone, address);
}

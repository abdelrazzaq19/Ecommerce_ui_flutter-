enum AddressType { home, office, other }

class Address {
  final String id;
  final String label;
  final String fullAddress;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;
  final AddressType type;

  const Address({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
    this.type = AddressType.home,
  });

  String get typeString => type.name;
}

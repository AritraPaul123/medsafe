class EmergencyContact {
  final String id;
  final String name;
  final String phone;

  EmergencyContact({required this.id, required this.name, required this.phone});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
      };
}

class MedicalInfo {
  final String bloodGroup;
  final String allergies;
  final String conditions;
  final String medications;
  final String emergencyMessage;

  MedicalInfo({
    required this.bloodGroup,
    required this.allergies,
    required this.conditions,
    required this.medications,
    required this.emergencyMessage,
  });

  factory MedicalInfo.fromJson(Map<String, dynamic> json) {
    return MedicalInfo(
      bloodGroup: json['bloodGroup'],
      allergies: json['allergies'],
      conditions: json['conditions'],
      medications: json['medications'],
      emergencyMessage: json['emergencyMessage'],
    );
  }

  Map<String, dynamic> toJson() => {
        'bloodGroup': bloodGroup,
        'allergies': allergies,
        'conditions': conditions,
        'medications': medications,
        'emergencyMessage': emergencyMessage,
      };
}

class UserLocation {
  final double latitude;
  final double longitude;
  final int timestamp;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
      };
}

class ManualLocation {
  final String? address;
  final double? latitude;
  final double? longitude;
  final int timestamp;

  ManualLocation({
    this.address,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });

  factory ManualLocation.fromJson(Map<String, dynamic> json) {
    return ManualLocation(
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
      };
}

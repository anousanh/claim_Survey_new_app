class UserAccount {
  final int id;
  final String adjusterCode;
  final String username;
  final String name;
  final String mobile;
  final String adjusterType;
  final int pvId;
  final int dtId;
  final double mapLat;
  final double mapLong;
  final String token;

  UserAccount({
    required this.id,
    required this.adjusterCode,
    required this.username,
    required this.name,
    required this.mobile,
    required this.adjusterType,
    required this.pvId,
    required this.dtId,
    required this.mapLat,
    required this.mapLong,
    required this.token,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['ID'] ?? 0,
      adjusterCode: json['Adjuster_Code'] ?? '',
      username: json['Username'] ?? '',
      name: json['Name'] ?? '',
      mobile: json['Mobile'] ?? '',
      adjusterType: json['Adjuster_Type'] ?? '',
      pvId: json['PV_ID'] ?? 0,
      dtId: json['DT_ID'] ?? 0,
      mapLat: (json['Map_Lat'] ?? 0).toDouble(),
      mapLong: (json['Map_Long'] ?? 0).toDouble(),
      token: json['Token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Adjuster_Code': adjusterCode,
      'Username': username,
      'Name': name,
      'Mobile': mobile,
      'Adjuster_Type': adjusterType,
      'PV_ID': pvId,
      'DT_ID': dtId,
      'Map_Lat': mapLat,
      'Map_Long': mapLong,
      'Token': token,
    };
  }

  @override
  String toString() {
    return 'UserAccount{id: $id, username: $username, name: $name, token: $token}';
  }
}

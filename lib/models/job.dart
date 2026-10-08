String _normalizeJobImageUrl(dynamic raw) {
  final value = (raw ?? '').toString().trim();
  if (value.isEmpty) return '';
  if (value.startsWith('http://') || value.startsWith('https://')) return value;
  if (value.startsWith('/')) return 'https://turnopronto.com.br' + value;
  return 'https://turnopronto.com.br/' + value;
}

class Job {
  final int id;
  final String role;
  final String title;
  final String imageUrl;
  final String company;
  final DateTime startsAt;
  final DateTime endsAt;
  final double value;
  final String address;
  final String city;
  final String state;
  final String dressCode;
  final String notes;
  final double companyRating;
  final int candidates;
  final double? distanceKm;
  final String distanceMode;
  final String acceptanceMode;
  final int requiredWorkers;
  final double? latitude;
  final double? longitude;
  final bool following;

  const Job({
    required this.id,
    required this.role,
    this.title = '',
    this.imageUrl = '',
    required this.company,
    required this.startsAt,
    required this.endsAt,
    required this.value,
    required this.address,
    required this.city,
    required this.state,
    required this.dressCode,
    required this.notes,
    this.companyRating = 4.9,
    this.candidates = 0,
    this.distanceKm,
    this.distanceMode = '',
    this.acceptanceMode = 'automatic',
    this.requiredWorkers = 1,
    this.latitude,
    this.longitude,
    this.following = false,
  });

  bool get requiresApproval => acceptanceMode == 'manual';
  bool get hasCoordinates => latitude != null && longitude != null;

  Job copyWith({
    double? distanceKm,
    String? distanceMode,
    double? latitude,
    double? longitude,
    bool? following,
  }) =>
      Job(
        id: id,
        role: role,
        title: title,
        imageUrl: imageUrl,
        company: company,
        startsAt: startsAt,
        endsAt: endsAt,
        value: value,
        address: address,
        city: city,
        state: state,
        dressCode: dressCode,
        notes: notes,
        companyRating: companyRating,
        candidates: candidates,
        distanceKm: distanceKm ?? this.distanceKm,
        distanceMode: distanceMode ?? this.distanceMode,
        acceptanceMode: acceptanceMode,
        requiredWorkers: requiredWorkers,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        following: following ?? this.following,
      );

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: int.parse(json['id'].toString()),
        role: (json['category_name'] ?? json['title'] ?? 'Turno').toString(),
        title: (json['title'] ?? json['category_name'] ?? 'Turno').toString(),
        imageUrl: _normalizeJobImageUrl(json['image_url']),
        company: (json['company_name'] ?? 'Empresa TurnoPronto').toString(),
        startsAt: DateTime.parse(json['starts_at'].toString()),
        endsAt: DateTime.parse(json['ends_at'].toString()),
        value: double.parse((json['shift_value'] ?? '0').toString()),
        address: (json['address'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
        state: (json['state'] ?? '').toString(),
        dressCode: (json['dress_code'] ?? '').toString(),
        notes: (json['notes'] ?? '').toString(),
        companyRating:
            double.tryParse((json['company_rating'] ?? '4.9').toString()) ?? 4.9,
        candidates: int.tryParse((json['candidates'] ?? '0').toString()) ?? 0,
        distanceKm: json['distance_km'] == null
            ? null
            : double.tryParse(json['distance_km'].toString()),
        distanceMode: (json['distance_mode'] ?? '').toString(),
        acceptanceMode:
            (json['acceptance_mode'] ?? 'automatic').toString(),
        requiredWorkers:
            int.tryParse((json['required_workers'] ?? '1').toString()) ?? 1,
        latitude: json['latitude'] == null
            ? null
            : double.tryParse(json['latitude'].toString()),
        longitude: json['longitude'] == null
            ? null
            : double.tryParse(json['longitude'].toString()),
        following: json['following'] == true ||
            json['following'].toString() == '1',
      );
}

class Assignment {
  final int id;
  final int shiftId;
  final String role;
  final String company;
  final DateTime startsAt;
  final DateTime endsAt;
  final double value;
  final String status;
  final String address;
  final String city;
  final String state;
  final DateTime? checkinAt;

  const Assignment({
    required this.id,
    required this.shiftId,
    required this.role,
    required this.company,
    required this.startsAt,
    required this.endsAt,
    required this.value,
    required this.status,
    required this.address,
    required this.city,
    required this.state,
    this.checkinAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: int.parse(json['id'].toString()),
        shiftId: int.parse(json['shift_id'].toString()),
        role: (json['category_name'] ?? json['title'] ?? 'Turno').toString(),
        company: (json['company_name'] ?? 'Empresa TurnoPronto').toString(),
        startsAt: DateTime.parse(json['starts_at'].toString()),
        endsAt: DateTime.parse(json['ends_at'].toString()),
        value: double.parse(
          (json['agreed_value'] ?? json['shift_value'] ?? '0').toString(),
        ),
        status: (json['status'] ?? 'confirmed').toString(),
        address: (json['address'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
        state: (json['state'] ?? '').toString(),
        checkinAt: json['checkin_at'] == null
            ? null
            : DateTime.tryParse(json['checkin_at'].toString()),
      );
}

class AcceptResult {
  const AcceptResult({required this.status, this.assignmentId});
  final String status;
  final int? assignmentId;

  bool get confirmed => assignmentId != null;
  bool get pendingApproval =>
      !confirmed && (status == 'applied' || status == 'verification_pending');
}

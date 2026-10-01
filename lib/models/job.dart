class Job {
  final int id;
  final String role;
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
  final double distanceKm;

  Job({
    required this.id,
    required this.role,
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
    this.candidates = 3,
    this.distanceKm = 2.1,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: int.parse(json['id'].toString()),
        role: (json['category_name'] ?? json['title'] ?? 'Turno').toString(),
        company: (json['company_name'] ?? 'Empresa TurnoPronto').toString(),
        startsAt: DateTime.parse(json['starts_at'].toString()),
        endsAt: DateTime.parse(json['ends_at'].toString()),
        value: double.parse(json['shift_value'].toString()),
        address: (json['address'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
        state: (json['state'] ?? '').toString(),
        dressCode: (json['dress_code'] ?? '').toString(),
        notes: (json['notes'] ?? '').toString(),
        companyRating: double.tryParse((json['company_rating'] ?? '4.9').toString()) ?? 4.9,
        candidates: int.tryParse((json['candidates'] ?? '3').toString()) ?? 3,
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

  Assignment({required this.id, required this.shiftId, required this.role, required this.company, required this.startsAt, required this.endsAt, required this.value, required this.status, required this.address, required this.city, required this.state, this.checkinAt});

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: int.parse(json['id'].toString()),
        shiftId: int.parse(json['shift_id'].toString()),
        role: (json['category_name'] ?? json['title'] ?? 'Turno').toString(),
        company: (json['company_name'] ?? 'Empresa TurnoPronto').toString(),
        startsAt: DateTime.parse(json['starts_at'].toString()),
        endsAt: DateTime.parse(json['ends_at'].toString()),
        value: double.parse((json['agreed_value'] ?? json['shift_value'] ?? '0').toString()),
        status: (json['status'] ?? 'confirmed').toString(),
        address: (json['address'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
        state: (json['state'] ?? '').toString(),
        checkinAt: json['checkin_at'] == null ? null : DateTime.tryParse(json['checkin_at'].toString()),
      );
}

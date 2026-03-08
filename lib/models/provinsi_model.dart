class ProvinceTarget {
  final int id;
  final String name;
  final int targetResponse;
  final int submissionResponse;

  ProvinceTarget({
    required this.id,
    required this.name,
    required this.targetResponse,
    this.submissionResponse = 0,
  });

  factory ProvinceTarget.fromJson(Map<String, dynamic> json) {
    return ProvinceTarget(
      // API pakai 'province_id' dan 'province_name'
      id: json['province_id'] ?? json['id'] ?? 0,
      name: json['province_name'] ?? json['name'] ?? '-',
      targetResponse:
          int.tryParse(json['target_response'].toString()) ?? 0,
      submissionResponse: json['submission_response'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'province_id': id,
      'province_name': name,
      'target_response': targetResponse,
      'submission_response': submissionResponse,
    };
  }

  @override
  String toString() => name;
}
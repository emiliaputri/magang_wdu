class ProvinceTarget {
  final int provinceId;
  final String targetResponse;
  final List<String> cities;
  final List<String> regencies;
  final String provinceName;
  final int submissionResponse;

  ProvinceTarget({
    required this.provinceId,
    required this.targetResponse,
    required this.cities,
    required this.regencies,
    required this.provinceName,
    required this.submissionResponse,
  });

  factory ProvinceTarget.fromJson(Map<String, dynamic> json) {
    return ProvinceTarget(
      provinceId: json['province_id'] ?? 0,
      targetResponse: json['target_response']?.toString() ?? '0',
      cities: (json['cities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      regencies: (json['regencies'] as List?)?.map((e) => e.toString()).toList() ?? [],
      provinceName: json['province_name']?.toString() ?? '',
      submissionResponse: json['submission_response'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'province_id': provinceId,
    'target_response': targetResponse,
    'cities': cities,
    'regencies': regencies,
    'province_name': provinceName,
    'submission_response': submissionResponse,
  };
}

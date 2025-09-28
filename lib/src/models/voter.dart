class Voter {
  final String id;
  final String flatNumber;
  final String name;
  final String phone;
  final String yadiNo;
  final String srNo;
  final String rscNumber;
  final String sector;
  final String buildingNo;
  final String buildingName;
  final String wing;
  final String comment;
  final String pollingBooth;

  Voter({
    required this.id,
    required this.flatNumber,
    required this.name,
    required this.phone,
    required this.yadiNo,
    required this.srNo,
    required this.rscNumber,
    required this.sector,
    required this.buildingNo,
    required this.buildingName,
    required this.wing,
    required this.comment,
    required this.pollingBooth,
  });

  factory Voter.fromMap(String id, Map<String, dynamic> m) => Voter(
    id: id,
    flatNumber: m['FLAT_NUMBER'] ?? '',
    name: m['NAME'] ?? '',
    phone: m['PHONE_NUMBER'] ?? '',
    yadiNo: m['YADI_NO'] ?? '',
    srNo: m['SR_NO'] ?? '',
    rscNumber: m['RSC_NUMBER'] ?? '',
    sector: m['SECTOR'] ?? '',
    buildingNo: m['BUILDING_NO'] ?? '',
    buildingName: m['BUILDING_NAME'] ?? '',
    wing: m['WING'] ?? '',
    comment: m['COMMENT'] ?? '',
    pollingBooth: m['POLLING_BOOTH'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'FLAT_NUMBER': flatNumber,
    'NAME': name,
    'PHONE_NUMBER': phone,
    'YADI_NO': yadiNo,
    'SR_NO': srNo,
    'RSC_NUMBER': rscNumber,
    'SECTOR': sector,
    'BUILDING_NO': buildingNo,
    'BUILDING_NAME': buildingName,
    'WING': wing,
    'COMMENT': comment,
    'POLLING_BOOTH': pollingBooth,
  };
}

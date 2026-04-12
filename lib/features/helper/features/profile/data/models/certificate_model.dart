import '../../domain/entities/certificate_entity.dart';

/// Data model for a helper's certificate.
/// Extends [CertificateEntity] to enforce the Data → Domain mapping pattern.
class CertificateModel extends CertificateEntity {
  const CertificateModel({
    required super.certificateId,
    required super.name,
    super.issuingOrganization,
    super.issueDate,
    super.expiryDate,
    super.certificateFileUrl,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      certificateId: json['certificateId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      issuingOrganization: json['issuingOrganization'] as String?,
      issueDate: json['issueDate'] != null
          ? DateTime.tryParse(json['issueDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
      certificateFileUrl: json['certificateFileUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'certificateId': certificateId,
      'name': name,
      'issuingOrganization': issuingOrganization,
      'issueDate': issueDate?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'certificateFileUrl': certificateFileUrl,
    };
  }
}

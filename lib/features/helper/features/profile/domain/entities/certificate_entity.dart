import 'package:equatable/equatable.dart';

/// Domain entity representing a professional certificate held by the helper.
class CertificateEntity extends Equatable {
  final String certificateId;
  final String name;
  final String? issuingOrganization;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? certificateFileUrl;

  const CertificateEntity({
    required this.certificateId,
    required this.name,
    this.issuingOrganization,
    this.issueDate,
    this.expiryDate,
    this.certificateFileUrl,
  });

  @override
  List<Object?> get props => [
        certificateId,
        name,
        issuingOrganization,
        issueDate,
        expiryDate,
        certificateFileUrl,
      ];
}

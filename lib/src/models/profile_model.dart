import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String kycTag;
  final String kycStatus;
  final String? profilePhotoUrl;
  final String primaryCurrency;

  const Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.kycTag,
    required this.kycStatus,
    this.profilePhotoUrl,
    required this.primaryCurrency,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      kycTag: json['kyc_tag'] as String? ?? '',
      kycStatus: json['kyc_status'] as String? ?? 'unverified',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      primaryCurrency: json['primary_currency'] as String? ?? 'KES',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'kyc_tag': kycTag,
      'kyc_status': kycStatus,
      'profile_photo_url': profilePhotoUrl,
      'primary_currency': primaryCurrency,
    };
  }

  Profile copyWith({
    String? firstName,
    String? lastName,
    String? kycTag,
    String? kycStatus,
    String? profilePhotoUrl,
    String? primaryCurrency,
  }) {
    return Profile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      kycTag: kycTag ?? this.kycTag,
      kycStatus: kycStatus ?? this.kycStatus,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        kycTag,
        kycStatus,
        profilePhotoUrl,
        primaryCurrency,
      ];
}

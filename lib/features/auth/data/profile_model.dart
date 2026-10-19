import '../domain/app_user.dart';
import '../domain/user_role.dart';

/// Shape of one row in the Supabase `profiles` table.
/// The data layer works with models; it converts them to domain
/// entities ([AppUser]) before handing them to the rest of the app.
class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.siteId,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'employee',
      siteId: json['site_id'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String role;
  final String? siteId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'role': role,
        'site_id': siteId,
      };

  AppUser toEntity({required String email}) => AppUser(
        id: id,
        email: email,
        fullName: fullName,
        role: UserRole.fromValue(role),
        siteId: siteId,
      );
}

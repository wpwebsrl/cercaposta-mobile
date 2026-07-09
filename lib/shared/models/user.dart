import '../../core/api/json.dart';

/// Subset of UserOut the app needs (locale drives date/number formatting).
class UserInfo {
  const UserInfo({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.language,
    required this.locale,
    required this.mustChangePassword,
  });

  final String id;
  final String username;
  final String displayName;
  final String role;
  final String language;
  final String locale;
  final bool mustChangePassword;

  String get label => displayName.isNotEmpty ? displayName : username;

  UserInfo copyWith({bool? mustChangePassword}) => UserInfo(
    id: id,
    username: username,
    displayName: displayName,
    role: role,
    language: language,
    locale: locale,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );

  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
    id: jsonStr(j, 'id'),
    username: jsonStr(j, 'username'),
    displayName: jsonStr(j, 'display_name'),
    role: jsonStr(j, 'role', 'user'),
    language: jsonStr(j, 'language', 'it'),
    locale: jsonStr(j, 'locale', 'it-IT'),
    mustChangePassword: jsonBool(j, 'must_change_password'),
  );
}

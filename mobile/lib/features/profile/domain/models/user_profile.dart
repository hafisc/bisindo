class UserProfile {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String role;
  final String? avatarUrl;
  final DateTime? joinedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.role,
    this.avatarUrl,
    this.joinedAt,
  });

  /// Profil kosong untuk pengguna yang belum login.
  static const empty = UserProfile(
    id: '',
    name: 'Pengguna',
    email: '-',
    studentId: '-',
    role: '-',
  );

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  /// Nama yang aman ditampilkan di UI (tidak pernah kosong).
  String get displayName => name.trim().isEmpty ? 'Pengguna' : name.trim();

  /// NIM yang aman ditampilkan di UI.
  String get displayStudentId =>
      studentId.trim().isEmpty ? 'Belum diisi' : studentId.trim();

  /// Peran yang aman ditampilkan di UI.
  String get displayRole => role.trim().isEmpty ? 'Pengguna BISINDO' : role.trim();

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    String? role,
    String? avatarUrl,
    DateTime? joinedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

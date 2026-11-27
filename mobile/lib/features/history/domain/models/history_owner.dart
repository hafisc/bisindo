/// Identitas pemilik riwayat yang dikirim ke server.
class HistoryOwner {
  const HistoryOwner({required this.uid, this.name, this.email});

  final String uid;
  final String? name;
  final String? email;

  // Dua owner dengan UID sama dianggap sama supaya riwayat tidak dimuat
  // ulang hanya karena nama atau email berubah.
  @override
  bool operator ==(Object other) => other is HistoryOwner && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}

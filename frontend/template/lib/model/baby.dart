// lib/models/baby.dart
class Baby {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? age;
  const Baby({required this.id,
              required this.name,
              this.avatarUrl, 
              this.age});
}

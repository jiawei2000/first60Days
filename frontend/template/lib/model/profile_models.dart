class Caregiver {
  String username; // display name
  String email;
  String phone;
  String? password; // optional for edit
  Caregiver({
    required this.username,
    required this.email,
    required this.phone,
    this.password,
  });
}

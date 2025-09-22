import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart'; // Adjust if needed

String? get_token(BuildContext context) {
  return Provider.of<AuthProvider>(context, listen: false).token;
}

import 'package:flutter/material.dart';

class InfoBanner extends StatelessWidget {
  final VoidCallback onClose;

  const InfoBanner({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.purple),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "This week your baby will learn to…..",
              style: TextStyle(color: Colors.black87),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 18),
          )
        ],
      ),
    );
  }
}

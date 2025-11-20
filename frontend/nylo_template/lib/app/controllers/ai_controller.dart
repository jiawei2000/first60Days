import 'package:flutter/widgets.dart';
import '/app/controllers/controller.dart';
import '/app/networking/ai_service.dart';

class AiController extends Controller {
  final AiService _aiService = AiService();

  @override
  construct(BuildContext context) async {
    super.construct(context);
  }

  Future<dynamic> askAssistant({
    required String question,
    required String babyId,
  }) async {
    return await _aiService.queryBabyAssistant(
      question: question,
      babyId: babyId,
    );
  }
}

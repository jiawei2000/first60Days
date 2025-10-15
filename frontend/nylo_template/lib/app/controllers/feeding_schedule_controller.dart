import 'package:flutter/widgets.dart';
import '/app/controllers/controller.dart';
import '/app/networking/feeding_schedule_api_service.dart';

class FeedingScheduleController extends Controller {
  final FeedingScheduleApiService _feedingScheduleApiService =
      FeedingScheduleApiService();

  @override
  construct(BuildContext context) async {
    super.construct(context);
  }

  Future<dynamic> fetchPlannerByBabyId(String babyId) async {
    return await _feedingScheduleApiService.getPlannerByBabyId(babyId: babyId);
  }

  Future<dynamic> fetchPlannerById(
      {required String babyId, required String plannerId}) async {
    return await _feedingScheduleApiService.getPlannerById(
      babyId: babyId,
      plannerId: plannerId,
    );
  }

  Future<dynamic> createPlanner(
      // {required String babyId, required Map<String, dynamic> data}) async {
      {required String babyId,
      required int weekNo,
      required DateTime firstFeedTime,
      required DateTime lastFeedTime,
      required int totalFeeds}) async {
    Map<String, dynamic> data = {
      'weekNo': weekNo,
      'firstFeedTime': firstFeedTime.toIso8601String(),
      'lastFeedTime': lastFeedTime.toIso8601String(),
      'totalFeeds': totalFeeds,
    };
    return await _feedingScheduleApiService.createPlanner(
      babyId: babyId,
      data: data,
    );
  }

  Future<dynamic> updatePlannerById({
    required String babyId,
    required String plannerId,
    required Map<String, dynamic> data,
  }) async {
    return await _feedingScheduleApiService.updatePlannerById(
      babyId: babyId,
      plannerId: plannerId,
      data: data,
    );
  }

  Future<dynamic> updateFeedTimingByPlannerId({
    required String babyId,
    required String plannerId,
    required Map<String, dynamic> data,
  }) async {
    return await _feedingScheduleApiService.updateFeedTimingByPlannerId(
      babyId: babyId,
      plannerId: plannerId,
      data: data,
    );
  }
}

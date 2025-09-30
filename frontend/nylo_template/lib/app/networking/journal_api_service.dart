import 'package:flutter/material.dart';
import '/config/decoders.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/journal_entry.dart';

class JournalApiService extends NyApiService {
  JournalApiService({BuildContext? buildContext})
      : super(
          buildContext,
          decoders: modelDecoders,
          baseOptions: (BaseOptions baseOptions) {
            return baseOptions
              ..connectTimeout = Duration(seconds: 5)
              ..sendTimeout = Duration(seconds: 5)
              ..receiveTimeout = Duration(seconds: 5);
          },
        );

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  //TODO: replace with actual token management
  String token =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IlZERjc1WEdqdG45UTBzaUdyYlZlIiwiZW1haWwiOiJob25nd2VpQGdtYWlsLmNvbSIsImlhdCI6MTc1OTIxOTQ0MSwiZXhwIjoxNzU5MzA1ODQxfQ.IkVH1YglCXXCB5QWQxvtrAvjijdN5JzZ3NM1EP7bxhU";

  /// Return a list of JournalEntry
  // Future<List<JournalEntry>?> fetchAll({dynamic query}) async {
  //   return await network<List<JournalEntry>>(
  //     request: (request) =>
  //         request.get("/endpoint-path", queryParameters: query),
  //   );
  // }

  /// Find a JournalEntry
  // Future<JournalEntry?> find({required dynamic data}) async {
  //   return await network<JournalEntry>(
  //     request: (request) =>
  //         request.post("/journalEntries/getEntryById", data: data),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     },
  //   );
  // }

  Future<List<JournalEntry>?> findAllforBabyId({required dynamic query}) async {
    return await network<List<JournalEntry>>(
      request: (request) => request.get("/journalEntries/$query"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// Create a JournalEntry
  Future<JournalEntry?> create(
      {required dynamic id, required dynamic data}) async {
    return await network<JournalEntry>(
      request: (request) =>
          request.post("/journalEntries/$id", data: data),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// Update a JournalEntry
  // Future<JournalEntry?> update({dynamic query}) async {
  //   return await network<JournalEntry>(
  //     request: (request) =>
  //         request.put("/endpoint-path", queryParameters: query),
  //   );
  // }

  /// Delete a JournalEntry
  // Future<bool?> destroy({required int id}) async {
  //   return await network<bool>(
  //     request: (request) => request.delete("/endpoint-path/$id"),
  //   );
  // }
}

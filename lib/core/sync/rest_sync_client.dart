/// VitalSync — AWS REST API Sync Client.
///
/// Implements [CloudSyncClient] using Amplify REST API (API Gateway + Lambda).
/// IAM-signed requests via Amplify.API — userId is extracted server-side
/// from the Cognito Identity ID in the API Gateway request context.
library;

import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

import 'cloud_sync_client.dart';

class RestSyncClient implements CloudSyncClient {
  /// Amplify REST API name (matches amplifyconfiguration.dart key).
  static const _apiName = 'vitalsynchApi';

  @override
  Future<DateTime?> pushRecord({
    required String userId,
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final body = jsonEncode({
      'records': [
        {
          'collection': collection,
          'recordId': recordId,
          'data': data,
          'lastModifiedAt': data['lastModifiedAt']?.toString() ?? now,
        },
      ],
    });

    final response = await Amplify.API
        .post(
          '/sync/push',
          apiName: _apiName,
          body: HttpPayload.string(body, contentType: 'application/json'),
        )
        .response;

    if (response.statusCode != 200) {
      throw Exception('Push failed: ${response.decodeBody()}');
    }

    // Return null — server handles timestamps via conditional write
    return null;
  }

  @override
  Future<void> deleteRecord({
    required String userId,
    required String collection,
    required String recordId,
  }) async {
    final body = jsonEncode({
      'collection': collection,
      'recordId': recordId,
    });

    final response = await Amplify.API
        .post(
          '/sync/delete',
          apiName: _apiName,
          body: HttpPayload.string(body, contentType: 'application/json'),
        )
        .response;

    if (response.statusCode != 200) {
      throw Exception('Delete failed: ${response.decodeBody()}');
    }
  }

  @override
  Future<List<CloudSyncRecord>> pullRecords({
    required String userId,
    required String collection,
    DateTime? since,
  }) async {
    final queryParams = <String, String>{};

    if (since != null) {
      queryParams['since'] = since.toUtc().toIso8601String();
    }

    // Send collection name — Lambda maps to SK prefix
    queryParams['collection'] = collection;

    final response = await Amplify.API
        .get(
          '/sync/pull',
          apiName: _apiName,
          queryParameters: queryParams,
        )
        .response;

    if (response.statusCode != 200) {
      throw Exception('Pull failed: ${response.decodeBody()}');
    }

    final json = jsonDecode(response.decodeBody()) as Map<String, dynamic>;
    final records = json['records'] as List<dynamic>? ?? [];

    return records.map((item) {
      final record = item as Map<String, dynamic>;
      final data = record['data'];

      return CloudSyncRecord(
        id: record['recordId'] as String,
        data: data is Map<String, dynamic>
            ? data
            : (data is String ? jsonDecode(data) as Map<String, dynamic> : {}),
        lastModifiedAt: DateTime.parse(record['lastModifiedAt'] as String),
      );
    }).toList();
  }

  @override
  Future<DateTime?> getRemoteModifiedAt({
    required String userId,
    required String collection,
    required String recordId,
  }) async {
    // Conflict detection is handled server-side via conditional writes
    // in the Lambda push endpoint (last-write-wins).
    // Returning null tells SyncService to proceed with push.
    return null;
  }

  @override
  Future<void> deleteAllUserData({
    required String userId,
    required List<String> collections,
  }) async {
    final response = await Amplify.API
        .delete(
          '/sync/user-data',
          apiName: _apiName,
        )
        .response;

    if (response.statusCode != 200) {
      throw Exception('User data deletion failed: ${response.decodeBody()}');
    }
  }

  @override
  Future<Map<String, dynamic>> exportAllUserData({
    required String userId,
    required List<String> collections,
  }) async {
    final response = await Amplify.API
        .get(
          '/sync/export',
          apiName: _apiName,
        )
        .response;

    if (response.statusCode != 200) {
      throw Exception('Export failed: ${response.decodeBody()}');
    }

    return jsonDecode(response.decodeBody()) as Map<String, dynamic>;
  }
}

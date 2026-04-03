import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qayd/core/error/exceptions.dart';
import 'package:qayd/data/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/app_document.dart';
import '../../domain/repositories/app_config_repository.dart';

class ApiAppConfigRepository implements AppConfigRepository {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;

  static const String _documentsCacheKey = 'cached_app_documents';
  static const String _offlineTicketsKey = 'offline_support_tickets';

  ApiAppConfigRepository({
    required this.apiClient,
    required this.sharedPreferences,
  });

  @override
  Future<Either<Failure, Map<String, AppDocument>>> getDocuments({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedData = sharedPreferences.getString(_documentsCacheKey);
        if (cachedData != null) {
          final decoded = json.decode(cachedData) as Map<String, dynamic>;
          final documents = <String, AppDocument>{};
          decoded.forEach((key, value) {
            documents[key] = AppDocument.fromJson(
              value as Map<String, dynamic>,
            );
          });
          if (documents.isNotEmpty) {
            // Initiate background fetch to keep cache fresh without blocking
            _fetchAndCacheDocuments();
            return right(documents);
          }
        }
      }

      final freshDocs = await _fetchAndCacheDocuments();
      return right(freshDocs);
    } catch (e) {
      if (e is AppException) {
        return left(NetworkFailure(messageAr: e.message));
      }
      return left(UnexpectedFailure(messageAr: e.toString()));
    }
  }

  Future<Map<String, AppDocument>> _fetchAndCacheDocuments() async {
    try {
      final response = await apiClient.get(ApiEndpoints.documents);
      debugPrint('AppConfig: Raw documents response: $response');

      if (response != null && response is Map<String, dynamic>) {
        final data = response;
        final documents = <String, AppDocument>{};
        final cacheMap = <String, dynamic>{};

        data.forEach((key, value) {
          try {
            debugPrint('AppConfig: Parsing document key: $key');
            final doc = AppDocument.fromJson(value as Map<String, dynamic>);
            documents[key] = doc;
            cacheMap[key] = doc.toJson();
          } catch (e) {
            debugPrint('AppConfig: Error parsing document $key: $e');
          }
        });

        debugPrint('AppConfig: Successfully parsed ${documents.length} documents. Keys: ${documents.keys.toList()}');

        if (documents.isNotEmpty) {
          await sharedPreferences.setString(
            _documentsCacheKey,
            json.encode(cacheMap),
          );
        }
        return documents;
      } else {
        debugPrint('AppConfig: Response is null or not a Map: $response');
      }
    } catch (e) {
      debugPrint('AppConfig: Global fetch error: $e');
    }
    return {};
  }

  @override
  Future<Either<Failure, void>> submitSupportTicket({
    required String type,
    required String message,
  }) async {
    try {
      String appVersion = '';
      String osVersion = '';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          osVersion = 'Android ${androidInfo.version.release}';
        } else if (Platform.isIOS) {
          final iosInfo = await DeviceInfoPlugin().iosInfo;
          osVersion = 'iOS ${iosInfo.systemVersion}';
        }
      } catch (_) {}

      final payload = {
        'type': type,
        'message': message,
        'app_version': appVersion,
        'os_version': osVersion,
      };

      await apiClient.post(ApiEndpoints.supportTickets, body: payload);

      // If we are back online, also try flushing offline tickets
      _flushOfflineTickets();

      return const Right(null);
    } catch (e) {
      // On network failure or any error, enqueue for later
      _queueOfflineTicket(type, message);
      // We return success gracefully as required by "Continue to function without any problems"
      return const Right(null);
    }
  }

  Future<void> _queueOfflineTicket(String type, String message) async {
    final ticketsStr = sharedPreferences.getString(_offlineTicketsKey) ?? '[]';
    final tickets = json.decode(ticketsStr) as List<dynamic>;

    tickets.add({
      'type': type,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await sharedPreferences.setString(_offlineTicketsKey, json.encode(tickets));
  }

  Future<void> _flushOfflineTickets() async {
    final ticketsStr = sharedPreferences.getString(_offlineTicketsKey);
    if (ticketsStr == null) return;

    final tickets = json.decode(ticketsStr) as List<dynamic>;
    if (tickets.isEmpty) return;

    final remainingTickets = [];

    for (final ticket in tickets) {
      try {
        final payload = {
          'type': ticket['type'],
          'message':
              ticket['message'] +
              '\n\n[Offline timestamp: ${ticket['timestamp']}]',
        };
        await apiClient.post(ApiEndpoints.supportTickets, body: payload);
      } catch (e) {
        remainingTickets.add(ticket);
      }
    }

    await sharedPreferences.setString(
      _offlineTicketsKey,
      json.encode(remainingTickets),
    );
  }
}

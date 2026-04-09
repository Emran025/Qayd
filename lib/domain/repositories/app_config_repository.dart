import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/app_document.dart';

abstract class AppConfigRepository {
  /// Fetches standard app documents (Terms of Use, Privacy Policy, FAQ)
  /// If forceRefresh is true, fetches from remote. Otherwise, attempts local first.
  Future<Either<Failure, Map<String, AppDocument>>> getDocuments(
      {bool forceRefresh = false});

  /// Submits a support ticket/bug report to the server.
  /// If offline, it should enqueue and return success.
  Future<Either<Failure, void>> submitSupportTicket({
    required String type,
    required String message,
  });
}

import 'package:qayd/presentation/l10n/app_strings.dart';

final class InvalidPosBarcodeException implements Exception {
  InvalidPosBarcodeException({String? messageAr})
      : messageAr = messageAr ?? AppStrings.posBarcodeInvalid;

  final String messageAr;

  @override
  String toString() => messageAr;
}

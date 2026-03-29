import 'package:uuid/uuid.dart';

/// Generates unique string identifiers for domain value objects (v4 UUIDs).
abstract interface class IdGenerator {
  String next();
}

final class UuidV4IdGenerator implements IdGenerator {
  UuidV4IdGenerator() : _uuid = Uuid();

  final Uuid _uuid;

  @override
  String next() => _uuid.v4();
}

# Changelog

## 0.3.0 (2026-06-10)

### Changed
- JWTs are now always signed locally with JOSE, regardless of `token_ttl_seconds`.
  Previously a TTL of exactly 3600 used the `apple` package's token builder.
- Removed the `apple` dependency.
- Narrowed token-generation `rescue` to expected error types so programmer errors propagate.

## 0.2.0 (2026-06-09)

- Coordinated version bump across all packages; added missing documentation

## 0.1.0 (2025-04-13)

- Initial release
- DeviceCheck API client
- Token validation and bit management

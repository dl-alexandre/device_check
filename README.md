# DeviceCheck

Elixir client for the [Apple DeviceCheck API](https://developer.apple.com/documentation/devicecheck).

It supports the server-side DeviceCheck endpoints for:

- validating a device token from `DCDevice`
- querying the two Apple-hosted fraud bits
- updating one or both bits

## Installation

Add to your `mix.exs`:

```elixir
defp deps do
  [
    {:device_check, "~> 0.1.0"}
  ]
end
```

## Configuration

```elixir
config :device_check,
  team_id: System.get_env("APPLE_TEAM_ID"),
  key_id: System.get_env("DEVICE_CHECK_KEY_ID"),
  private_key_path: System.get_env("DEVICE_CHECK_PRIVATE_KEY_PATH"),
  development: true
```

Supported options:

- `team_id` - Apple Developer Team ID
- `key_id` - DeviceCheck key ID
- `private_key` - inline `.p8` contents
- `private_key_path` - path to the `.p8` file
- `development` - `true` for `api.development.devicecheck.apple.com`
- `token_ttl_seconds` - defaults to `3600`

## Quick Start

```elixir
# Generate the JWT used for DeviceCheck requests
{:ok, token} = DeviceCheck.token()

# Validate a device token from the client app
{:ok, _} = DeviceCheck.validate_token(device_token)

# Query current bit state
{:ok, result} = DeviceCheck.query_bits(device_token)

# Update one or both bits
{:ok, _} = DeviceCheck.update_bits(device_token, bit0: true, bit1: false)
```

## Request Metadata

The client automatically generates:

- `transaction_id`
- `timestamp` in milliseconds

You can override them when needed:

```elixir
DeviceCheck.validate_token(device_token,
  transaction_id: "123e4567-e89b-12d3-a456-426614174000",
  timestamp: 1_700_000_000_000
)
```

## Live Testing

Run the included smoke test:

```bash
cd device_check
elixir test_live.exs
```

To exercise Apple’s live endpoints, set a real device token in `.env`:

```bash
export DEVICE_CHECK_TEST_DEVICE_TOKEN="base64-token-from-dcdevice"
```

## Notes

- `query_bits/2` returns `{:ok, :bit_state_not_found}` when Apple has no stored bit state yet.
- `update_bits/2` requires at least one of `bit0` or `bit1`.
- Device tokens come from the client app via `DCDevice`, not from this library.

## License

MIT

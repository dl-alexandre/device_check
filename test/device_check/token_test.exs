defmodule DeviceCheck.TokenTest do
  use ExUnit.Case, async: true

  alias DeviceCheck.Token

  setup do
    private_key = DeviceCheck.TestKey.generate_private_key()

    {:ok, %{opts: [team_id: "TEAMID1234", key_id: "KEYID56789", private_key: private_key]}}
  end

  test "returns a valid JWT token string", %{opts: opts} do
    assert {:ok, token} = Token.generate_jwt(opts)
    assert is_binary(token)
    assert length(String.split(token, ".")) == 3
  end

  test "JWT contains correct header", %{opts: opts} do
    {:ok, token} = Token.generate_jwt(opts)
    [header_b64 | _] = String.split(token, ".")
    {:ok, header} = Base.url_decode64(header_b64, padding: false)
    header_json = Jason.decode!(header)

    assert header_json["alg"] == "ES256"
    assert header_json["kid"] == "KEYID56789"
    assert header_json["typ"] == "JWT"
  end

  test "JWT contains correct claims", %{opts: opts} do
    {:ok, token} = Token.generate_jwt(opts)
    [_, payload_b64 | _] = String.split(token, ".")
    {:ok, payload} = Base.url_decode64(payload_b64, padding: false)
    claims = Jason.decode!(payload)

    assert claims["iss"] == "TEAMID1234"
    assert is_integer(claims["iat"])
    assert is_integer(claims["exp"])
    assert claims["exp"] == claims["iat"] + 3600
  end

  test "respects custom token_ttl_seconds", %{opts: opts} do
    {:ok, token} = Token.generate_jwt(Keyword.put(opts, :token_ttl_seconds, 600))
    [_, payload_b64 | _] = String.split(token, ".")
    {:ok, payload} = Base.url_decode64(payload_b64, padding: false)
    claims = Jason.decode!(payload)

    assert claims["exp"] == claims["iat"] + 600
  end

  test "returns error for missing fields" do
    assert {:error, {:missing_config, _}} =
             Token.generate_jwt(team_id: nil, key_id: nil, private_key: nil)
  end

  test "returns token with expiry timestamp", %{opts: opts} do
    assert {:ok, token, expires_at} = Token.access_token_with_expiry(opts)
    assert is_binary(token)
    assert is_integer(expires_at)
  end
end

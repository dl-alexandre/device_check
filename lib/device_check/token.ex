defmodule DeviceCheck.Token do
  @moduledoc """
  DeviceCheck API token generation.

  DeviceCheck uses a JWT signed with your DeviceCheck-enabled private key (ES256).
  The JWT is used directly as the Bearer token in API requests.
  """

  alias Apple.DeviceCheckAPI
  alias DeviceCheck.Config

  @type jwt :: String.t()

  @doc "Generate a fresh ES256 JWT for DeviceCheck API authorization."
  @spec generate_jwt(keyword()) :: {:ok, jwt()} | {:error, term()}
  def generate_jwt(opts \\ []) do
    config = Config.load(opts)
    now = System.system_time(:second)

    with {:ok, team_id} <- require_field(config.team_id, :team_id),
         {:ok, key_id} <- require_field(config.key_id, :key_id) do
      claims = %{
        "iss" => team_id,
        "iat" => now,
        "exp" => now + config.token_ttl_seconds
      }

      header = %{
        "alg" => "ES256",
        "kid" => key_id,
        "typ" => "JWT"
      }

      try do
        compact =
          if config.token_ttl_seconds == 3600 do
            DeviceCheckAPI.build_auth_token!(team_id, key_id, Config.private_key_pem!(config))
          else
            sign_locally(config, header, claims)
          end

        {:ok, compact}
      rescue
        e -> {:error, {:token_generation_failed, Exception.message(e)}}
      end
    end
  end

  @doc "Returns a JWT token (same as generate_jwt for direct use)."
  @spec access_token(keyword()) :: {:ok, String.t()} | {:error, term()}
  def access_token(opts \\ []) do
    generate_jwt(opts)
  end

  @doc "Generate a JWT and return it with the expiration timestamp."
  @spec access_token_with_expiry(keyword()) :: {:ok, String.t(), integer()} | {:error, term()}
  def access_token_with_expiry(opts \\ []) do
    config = Config.load(opts)

    with {:ok, token} <- generate_jwt(opts) do
      expires_at = System.system_time(:second) + config.token_ttl_seconds
      {:ok, token, expires_at}
    end
  end

  defp require_field(nil, name), do: {:error, {:missing_config, name}}
  defp require_field("", name), do: {:error, {:missing_config, name}}
  defp require_field(value, _), do: {:ok, value}

  defp sign_locally(config, header, claims) do
    jwk = Config.private_key_pem!(config) |> JOSE.JWK.from_pem()
    {_, compact} = JOSE.JWT.sign(jwk, header, claims) |> JOSE.JWS.compact()
    compact
  end
end

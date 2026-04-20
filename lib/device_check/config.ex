defmodule DeviceCheck.Config do
  @moduledoc false

  @default_base_url "https://api.devicecheck.apple.com"
  @default_development_url "https://api.development.devicecheck.apple.com"
  @default_ttl 60 * 60

  defstruct [
    :team_id,
    :key_id,
    :private_key,
    :private_key_path,
    :base_url,
    :development,
    :token_ttl_seconds,
    :req_options
  ]

  @type t :: %__MODULE__{
          team_id: String.t() | nil,
          key_id: String.t() | nil,
          private_key: String.t() | nil,
          private_key_path: String.t() | nil,
          base_url: String.t(),
          development: boolean(),
          token_ttl_seconds: pos_integer(),
          req_options: keyword()
        }

  @doc "Load configuration from Application env merged with runtime opts."
  @spec load(keyword()) :: t()
  def load(opts \\ []) do
    env = Application.get_all_env(:device_check)
    merged = Keyword.merge(env, opts)
    development = Keyword.get(merged, :development, false)

    %__MODULE__{
      team_id: fetch(merged, :team_id),
      key_id: fetch(merged, :key_id),
      private_key: fetch(merged, :private_key),
      private_key_path: fetch(merged, :private_key_path),
      base_url:
        Keyword.get(
          merged,
          :base_url,
          if(development, do: @default_development_url, else: @default_base_url)
        ),
      development: development,
      token_ttl_seconds: Keyword.get(merged, :token_ttl_seconds, @default_ttl),
      req_options: Keyword.get(merged, :req_options, [])
    }
  end

  @doc "Extract the private key PEM from config (either from string or file path)."
  @spec private_key_pem!(t()) :: String.t()
  def private_key_pem!(%__MODULE__{private_key: pem}) when is_binary(pem) and pem != "", do: pem

  def private_key_pem!(%__MODULE__{private_key_path: path}) when is_binary(path) and path != "" do
    File.read!(path)
  end

  def private_key_pem!(_), do: raise(ArgumentError, "missing :private_key or :private_key_path")

  defp fetch(kw, key) do
    case Keyword.get(kw, key) do
      "" -> nil
      value -> value
    end
  end
end

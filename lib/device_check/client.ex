defmodule DeviceCheck.Client do
  @moduledoc false

  alias DeviceCheck.{Config, Error, Token, TokenCache}

  @config_keys [
    :team_id,
    :key_id,
    :private_key,
    :private_key_path,
    :base_url,
    :development,
    :token_ttl_seconds,
    :req_options
  ]

  @spec post(String.t(), map(), keyword()) :: {:ok, term()} | {:error, term()}
  def post(path, body, opts) do
    {config_opts, _meta, _params} = split_opts(opts)
    config = Config.load(config_opts)

    with {:ok, access_token} <- fetch_access_token(config_opts) do
      req =
        Req.new(
          base_url: config.base_url,
          headers: [
            {"accept", "application/json"},
            {"content-type", "application/json"},
            {"authorization", "Bearer #{access_token}"}
          ]
        )
        |> Req.merge(config.req_options)

      req
      |> Req.post(url: path, json: body)
      |> normalize()
    end
  end

  defp fetch_access_token([]), do: TokenCache.fetch()
  defp fetch_access_token(config_opts), do: Token.access_token(config_opts)

  defp split_opts(opts) do
    {config, rest} = Keyword.split(opts, @config_keys)
    {meta, params} = Keyword.split(rest, [])
    {config, meta, params}
  end

  defp normalize({:ok, %Req.Response{status: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  defp normalize({:ok, %Req.Response{status: status, body: body}}) do
    {:error, Error.from_http(status, body)}
  end

  defp normalize({:error, reason}) do
    {:error, {:transport_error, reason}}
  end
end

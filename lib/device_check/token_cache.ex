defmodule DeviceCheck.TokenCache do
  @moduledoc """
  Caches the DeviceCheck token so we don't sign a new JWT on every call.

  The cache is keyed by application env config. Pass per-call opts to bypass it.
  Tokens are refreshed automatically when they're within `@refresh_buffer_seconds`
  of expiry.
  """

  use GenServer

  alias DeviceCheck.Token

  @refresh_buffer_seconds 60

  @doc "Start the token cache GenServer."
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  @doc "Fetch a cached token, generating a new one if expired or not present."
  @spec fetch() :: {:ok, String.t()} | {:error, term()}
  def fetch(server \\ __MODULE__) do
    GenServer.call(server, :fetch)
  end

  @doc "Clear the cached token, forcing a new token on next fetch."
  @spec clear() :: :ok
  def clear(server \\ __MODULE__) do
    GenServer.call(server, :clear)
  end

  @impl true
  def init(:ok), do: {:ok, %{token: nil, expires_at: 0}}

  @impl true
  def handle_call(:fetch, _from, state) do
    now = System.system_time(:second)

    if state.token && state.expires_at - now > @refresh_buffer_seconds do
      {:reply, {:ok, state.token}, state}
    else
      case Token.access_token_with_expiry() do
        {:ok, token, expires_at} ->
          {:reply, {:ok, token}, %{token: token, expires_at: expires_at}}

        {:error, _} = error ->
          {:reply, error, state}
      end
    end
  end

  @impl true
  def handle_call(:clear, _from, _state) do
    {:reply, :ok, %{token: nil, expires_at: 0}}
  end
end

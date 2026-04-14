defmodule DeviceCheck.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [DeviceCheck.TokenCache]

    Supervisor.start_link(children, strategy: :one_for_one, name: DeviceCheck.Supervisor)
  end
end

defmodule DeviceCheck.TestKey do
  @moduledoc false

  @spec generate_private_key() :: String.t()
  def generate_private_key do
    private_key = JOSE.JWK.generate_key({:ec, "P-256"})
    JOSE.JWK.to_pem(private_key) |> elem(1)
  end
end

defmodule DeviceCheck.TokenCacheTest do
  use ExUnit.Case, async: false

  alias DeviceCheck.TokenCache

  setup do
    private_key = DeviceCheck.TestKey.generate_private_key()
    original_env = Application.get_all_env(:device_check)

    Application.put_all_env(
      device_check: [
        team_id: "TEAMID1234",
        key_id: "KEYID56789",
        private_key: private_key
      ]
    )

    TokenCache.clear()

    on_exit(fn ->
      Application.put_all_env(device_check: original_env)
    end)

    :ok
  end

  test "generates and caches token" do
    assert {:ok, token1} = TokenCache.fetch()
    assert {:ok, token2} = TokenCache.fetch()
    assert token1 == token2
  end

  test "clear forces a new token" do
    assert {:ok, token1} = TokenCache.fetch()
    assert :ok = TokenCache.clear()
    assert {:ok, token2} = TokenCache.fetch()
    assert token1 != token2
  end
end

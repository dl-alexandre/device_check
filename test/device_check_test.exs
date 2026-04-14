defmodule DeviceCheckTest do
  use ExUnit.Case, async: false

  setup do
    bypass = Bypass.open()
    private_key = DeviceCheck.TestKey.generate_private_key()
    original_env = Application.get_all_env(:device_check)

    Application.put_all_env(
      device_check: [
        team_id: "TEAMID1234",
        key_id: "KEYID56789",
        private_key: private_key,
        base_url: "http://localhost:#{bypass.port}",
        development: true
      ]
    )

    DeviceCheck.TokenCache.clear()

    on_exit(fn ->
      Application.put_all_env(device_check: original_env)
    end)

    {:ok, %{bypass: bypass}}
  end

  test "query_bits returns normalized bit state", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["device_token"] == "device-token"
      assert is_binary(payload["transaction_id"])
      assert is_integer(payload["timestamp"])

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        Jason.encode!(%{"bit0" => true, "bit1" => false, "last_update_time" => "2026-04"})
      )
    end)

    assert {:ok, %{bit0: true, bit1: false, last_update_time: "2026-04"}} =
             DeviceCheck.query_bits("device-token")
  end

  test "query_bits returns :bit_state_not_found for Apple text response", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "Bit State Not Found")
    end)

    assert {:ok, :bit_state_not_found} = DeviceCheck.query_bits("device-token")
  end

  test "update_bits includes only provided bits", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["bit0"] == true
      refute Map.has_key?(payload, "bit1")
      Plug.Conn.resp(conn, 200, "")
    end)

    assert {:ok, %{}} = DeviceCheck.update_bits("device-token", bit0: true)
  end

  test "update_bits requires at least one bit" do
    assert {:error, {:missing_update_bits, [:bit0, :bit1]}} =
             DeviceCheck.update_bits("device-token")
  end

  test "validate_token accepts explicit transaction metadata", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      payload = Jason.decode!(body)
      assert payload["transaction_id"] == "123e4567-e89b-12d3-a456-426614174000"
      assert payload["timestamp"] == 1_700_000_000_000
      Plug.Conn.resp(conn, 200, "")
    end)

    assert {:ok, ""} =
             DeviceCheck.validate_token(
               "device-token",
               transaction_id: "123e4567-e89b-12d3-a456-426614174000",
               timestamp: 1_700_000_000_000
             )
  end
end

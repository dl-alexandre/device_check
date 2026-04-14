defmodule DeviceCheck.ClientTest do
  use ExUnit.Case, async: false

  alias DeviceCheck.Client

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

  test "successfully makes authenticated request", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      assert conn.method == "POST"
      assert conn.request_path == "/v1/query_two_bits"

      headers = Enum.map(conn.req_headers, fn {k, _} -> k end)
      assert "authorization" in headers
      assert "content-type" in headers

      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert %{"device_token" => "abc", "transaction_id" => _, "timestamp" => _} =
               Jason.decode!(body)

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"bit0" => true, "bit1" => false}))
    end)

    assert {:ok, %{"bit0" => true, "bit1" => false}} =
             Client.post(
               "/v1/query_two_bits",
               %{device_token: "abc", transaction_id: "x", timestamp: 1},
               []
             )
  end

  test "handles HTTP errors", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(400, Jason.encode!(%{"reason" => "Bad Device Token"}))
    end)

    assert {:error, %DeviceCheck.Error{status: 400}} =
             Client.post("/v1/validate_device_token", %{device_token: "abc"}, [])
  end

  test "handles network errors", %{bypass: bypass} do
    Bypass.down(bypass)

    assert {:error, {:transport_error, _}} =
             Client.post("/v1/query_two_bits", %{device_token: "abc"}, [])
  end

  test "uses per-call config overrides", %{bypass: bypass} do
    override_key = DeviceCheck.TestKey.generate_private_key()

    Bypass.expect(bypass, fn conn ->
      assert conn.request_path == "/v1/validate_device_token"
      Plug.Conn.resp(conn, 200, "")
    end)

    assert {:ok, _} =
             Client.post(
               "/v1/validate_device_token",
               %{device_token: "abc"},
               base_url: "http://localhost:#{bypass.port}",
               team_id: "TEAMID1234",
               key_id: "KEYID56789",
               private_key: override_key
             )
  end
end

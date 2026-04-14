#!/usr/bin/env elixir

Mix.install([
  {:device_check, path: "."},
  {:dotenv, "~> 3.0"}
])

Dotenv.load()

defmodule DeviceCheckLiveTest do
  def run do
    IO.puts("=" <> String.duplicate("=", 70))
    IO.puts("DEVICECHECK LIVE TEST")
    IO.puts("=" <> String.duplicate("=", 70))
    IO.puts("")

    configure_from_env()

    {:ok, _} = Application.ensure_all_started(:device_check)
    IO.puts("✅ DeviceCheck application started")
    IO.puts("")

    IO.puts("Configuration:")
    IO.puts("  Team ID: #{System.get_env("APPLE_TEAM_ID") || "NOT SET"}")
    IO.puts("  Key ID: #{System.get_env("DEVICE_CHECK_KEY_ID") || "NOT SET"}")
    IO.puts("  Development: #{System.get_env("DEVICE_CHECK_DEVELOPMENT") || "false"}")
    IO.puts("  Key File: #{System.get_env("DEVICE_CHECK_PRIVATE_KEY_PATH") || "NOT SET"}")
    IO.puts("")

    IO.puts("► Test 1: JWT Token Generation")
    IO.puts(String.duplicate("-", 50))

    case DeviceCheck.token() do
      {:ok, token} ->
        IO.puts("✅ Token generated successfully")
        IO.puts("   Length: #{String.length(token)} characters")
        IO.puts("   Preview: #{String.slice(token, 0, 50)}...")
        IO.puts("")
        maybe_run_device_tests()

      {:error, reason} ->
        IO.puts("❌ Token generation failed")
        IO.puts("   Reason: #{inspect(reason)}")
    end

    IO.puts("")
    IO.puts("=" <> String.duplicate("=", 70))
    IO.puts("Test complete")
    IO.puts("=" <> String.duplicate("=", 70))
  end

  defp configure_from_env do
    Application.put_env(:device_check, :team_id, System.get_env("APPLE_TEAM_ID"))
    Application.put_env(:device_check, :key_id, System.get_env("DEVICE_CHECK_KEY_ID"))

    Application.put_env(
      :device_check,
      :private_key_path,
      System.get_env("DEVICE_CHECK_PRIVATE_KEY_PATH")
    )

    Application.put_env(
      :device_check,
      :development,
      System.get_env("DEVICE_CHECK_DEVELOPMENT", "false") == "true"
    )
  end

  defp maybe_run_device_tests do
    case System.get_env("DEVICE_CHECK_TEST_DEVICE_TOKEN") do
      nil ->
        print_skip()

      "" ->
        print_skip()

      device_token ->
        run_validate_test(device_token)
        run_query_test(device_token)
    end
  end

  defp run_validate_test(device_token) do
    IO.puts("► Test 2: Validate Device Token")
    IO.puts(String.duplicate("-", 50))

    case DeviceCheck.validate_token(device_token) do
      {:ok, response} ->
        IO.puts("✅ Device token accepted by Apple")
        IO.puts("   Response: #{inspect(response)}")

      {:error, %DeviceCheck.Error{} = error} ->
        IO.puts("❌ Validation failed")
        IO.puts("   Status: #{error.status}")
        IO.puts("   Message: #{error.message}")
        IO.puts("   Details: #{inspect(error.details)}")

      {:error, reason} ->
        IO.puts("❌ Validation failed")
        IO.puts("   Reason: #{inspect(reason)}")
    end

    IO.puts("")
  end

  defp run_query_test(device_token) do
    IO.puts("► Test 3: Query Two Bits")
    IO.puts(String.duplicate("-", 50))

    case DeviceCheck.query_bits(device_token) do
      {:ok, :bit_state_not_found} ->
        IO.puts("✅ Device token accepted; no bit state set yet")

      {:ok, %{bit0: bit0, bit1: bit1} = response} ->
        IO.puts("✅ Bit state retrieved")
        IO.puts("   bit0: #{bit0}")
        IO.puts("   bit1: #{bit1}")
        IO.puts("   response: #{inspect(response)}")

      {:error, %DeviceCheck.Error{} = error} ->
        IO.puts("❌ Query failed")
        IO.puts("   Status: #{error.status}")
        IO.puts("   Message: #{error.message}")
        IO.puts("   Details: #{inspect(error.details)}")

      {:error, reason} ->
        IO.puts("❌ Query failed")
        IO.puts("   Reason: #{inspect(reason)}")
    end
  end

  defp print_skip do
    IO.puts("► Test 2: DeviceCheck API Calls")
    IO.puts(String.duplicate("-", 50))
    IO.puts("⏭️  Skipped: set DEVICE_CHECK_TEST_DEVICE_TOKEN in .env to call Apple")
  end
end

DeviceCheckLiveTest.run()

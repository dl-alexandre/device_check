defmodule DeviceCheck.Error do
  @moduledoc "Structured error returned from the DeviceCheck API."

  defexception [:message, :status, :details]

  @type t :: %__MODULE__{
          message: String.t(),
          status: non_neg_integer() | nil,
          details: term()
        }

  @doc "Create an error struct from an HTTP response status and body."
  @spec from_http(non_neg_integer(), term()) :: t()
  def from_http(status, body) do
    %__MODULE__{
      message: reason_for(status),
      status: status,
      details: body
    }
  end

  defp reason_for(200), do: "DeviceCheck responded with a non-JSON success body"

  defp reason_for(400),
    do: "bad request — invalid request payload or badly formatted device token"

  defp reason_for(401), do: "unauthorized — invalid or expired DeviceCheck token"
  defp reason_for(403), do: "forbidden — DeviceCheck capability or environment access denied"
  defp reason_for(404), do: "not found — DeviceCheck endpoint does not exist"
  defp reason_for(429), do: "rate limited by DeviceCheck API"
  defp reason_for(500), do: "internal server error — Apple server error"
  defp reason_for(503), do: "service unavailable — maintenance or outage"
  defp reason_for(_), do: "DeviceCheck API request failed"
end

defmodule PrxClient.Error do
  defstruct [:status, :url, :message, :json]

  def build(status, url, "" <> body) do
    case Poison.decode(body) do
      {:ok, json} -> build_json(status, url, json)
      _not_json -> build_text(status, url, body)
    end
  end

  def build(status, url, body), do: build_json(status, url, body)

  def for_resource(%PrxClient.Resource{_status: status, _url: url}, "" <> msg) do
    {:error, %PrxClient.Error{status: status, url: url, message: msg}}
  end

  defp build_json(status, url, json) do
    err = %PrxClient.Error{
      status: status,
      url: url,
      message: "Got #{status} for #{url}",
      json: json
    }

    {:error, err}
  end

  defp build_text(200, url, text) do
    err = %PrxClient.Error{
      status: 200,
      url: url,
      message: "JSON decode error: #{text}"
    }

    {:error, err}
  end

  defp build_text(status, url, text) do
    err = %PrxClient.Error{
      status: status,
      url: url,
      message: text
    }

    {:error, err}
  end
end

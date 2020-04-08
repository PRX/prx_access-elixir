defmodule PrxAccess.Error do
  defstruct [:status, :url, :message, :json]

  def build(status, url, "" <> body) do
    case Poison.decode(body) do
      {:ok, json} -> build_json(status, url, json)
      _not_json -> build_text(status, url, body)
    end
  end

  def build(status, url, body), do: build_json(status, url, body)

  def for_resource(%PrxAccess.Resource{_status: status, _url: url}, "" <> msg) do
    {:error, %PrxAccess.Error{status: status, url: url, message: msg}}
  end

  defp build_json(status, url, json) do
    err = %PrxAccess.Error{
      status: status,
      url: url,
      message: "Got #{status} for #{url}",
      json: json
    }

    {:error, err}
  end

  defp build_text(200, url, text) do
    err = %PrxAccess.Error{
      status: 200,
      url: url,
      message: "JSON decode error: #{text}"
    }

    {:error, err}
  end

  defp build_text(status, url, ""), do: build_text(status, url, "Got #{status} for #{url}")

  defp build_text(status, url, text) do
    err = %PrxAccess.Error{
      status: status,
      url: url,
      message: text
    }

    {:error, err}
  end
end

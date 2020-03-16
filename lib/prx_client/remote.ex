defmodule PrxClient.Remote do
  def get(url) do
    case http_library().get(url, headers()) do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        PrxClient.Resource.build(status, url, body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        PrxClient.Error.build(nil, url, reason)
    end
  end

  defp headers do
    [{"Accept", "application/hal+json"}]
  end

  defp http_library do
    Application.get_env(:prx_client, :http_library) || HTTPoison
  end
end

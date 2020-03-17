defmodule PrxClient.Remote do
  def get(url, token \\ nil) do
    case HTTPoison.get(url, headers(token)) do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        PrxClient.Resource.build(status, url, token, body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        PrxClient.Error.build(nil, url, reason)
    end
  end

  def host_to_api(host), do: "#{host_to_url(host)}/api/v1"

  def host_to_url("http" <> host), do: host
  def host_to_url(host), do: "https://#{host}"

  defp headers(nil) do
    [{"Accept", "application/hal+json"}]
  end

  defp headers(token) do
    [{"Accept", "application/hal+json"}, {"Authorization", "Bearer #{token}"}]
  end
end

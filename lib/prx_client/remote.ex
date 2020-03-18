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

  def host_to_url(host) do
    if host =~ ~r/localhost|127\.0\.0\.1/ do
      "http://#{host}"
    else
      "https://#{host}"
    end
  end

  def user_agent do
    "PrxClientElixir/#{Mix.Project.config()[:version]}"
  end

  defp headers(nil) do
    [{"Accept", "application/hal+json"}, {"User-Agent", user_agent()}]
  end

  defp headers(token) do
    headers(nil) ++ [{"Authorization", "Bearer #{token}"}]
  end
end

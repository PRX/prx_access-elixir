defmodule PrxClient do
  @moduledoc """
  Documentation for PrxClient.
  """

  alias PrxClient.Resource
  alias PrxClient.Resource.Link

  @doc """
  Get the root resource for a hostname
  """
  def root("" <> host) do
    get(%{url: "https://#{host}/api/v1"})
  end

  def links(%Resource{_links: links}, "" <> rel), do: links[rel]
  def links({:ok, res}, rel), do: links(res, rel)
  def links(err, _rel), do: err

  def link(%Resource{_url: url} = res, "" <> rel) do
    case links(res, rel) do
      [first_link | _rest] -> {:ok, first_link}
      %Link{} = single_link -> {:ok, single_link}
      _ -> {:error, "Unknown rel #{rel} on #{url}"}
    end
  end

  def link({:ok, res}, rel), do: link(res, rel)
  def link(err, _rel), do: err

  def rels(%Resource{_links: links}), do: Map.keys(links)
  def rels({:ok, res}), do: rels(res)
  def rels(err), do: err

  def follow(res, rel), do: follow(res, rel, [])
  def follow({:ok, res}, rel, params), do: follow(res, rel, params)
  def follow({:error, err}, _rel, _params), do: {:error, err}

  def follow(%Resource{} = res, "" <> rel, params) do
    case link(res, rel) do
      {:ok, link} -> follow(res, link, params)
      err -> err
    end
  end

  def follow(%Resource{_url: prev_url} = res, %Link{href: href}, params) do
    url = URI.merge(prev_url, UriTemplate.expand(href, params))
    get(%{url: to_string(url)})
  end

  def get(%{url: url}) do
    headers = [{"Accept", "application/hal+json"}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        case Poison.decode(body) do
          {:ok, json} -> to_resource(json, url, status)
          _not_json -> to_error(body, url, status)
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        to_error(reason, url, nil)
    end
  end

  defp to_resource(json, url, 200) do
    res =
      PrxClient.Resource.from_json(json)
      |> Map.put(:_url, url)
      |> Map.put(:_status, 200)

    {:ok, res}
  end

  defp to_resource(json, url, not_ok_status) do
    json
    |> Map.put(:message, "Non-ok status #{not_ok_status} for #{url}")
    |> to_error(url, not_ok_status)
  end

  defp to_error("" <> msg, url, status) do
    to_error(%{message: msg}, url, status)
  end

  defp to_error(json, url, status) do
    err =
      %PrxClient.Error{}
      |> struct(json)
      |> Map.put(:url, url)
      |> Map.put(:status, status)

    {:error, err}
  end
end

defmodule PrxClient do
  @moduledoc """
  Client library for interacting with PRX APIs
  """

  alias PrxClient.Remote
  alias PrxClient.Resource
  alias PrxClient.Resource.Link
  alias PrxClient.Error

  @doc """
  Get the root resource for a hostname
  """
  def root("" <> host) do
    Remote.get("https://#{host}/api/v1")
  end

  def links(%Resource{_links: links} = res, "" <> rel) do
    case Map.get(links, rel) do
      nil -> Error.for_resource(res, "rel #{rel} not found")
      links -> {:ok, links}
    end
  end

  def links({:ok, res}, rel), do: links(res, rel)
  def links(err, _rel), do: err

  def link(res, rel) do
    case links(res, rel) do
      {:ok, [first_link | _rest]} -> {:ok, first_link}
      {:ok, single_link} -> {:ok, single_link}
      err -> err
    end
  end

  def link?(res, rel) do
    case links(res, rel) do
      {:ok, _} -> true
      _err -> false
    end
  end

  def rels(%Resource{_links: links, _embedded: embedded}) do
    {:ok, Enum.uniq(Map.keys(links) ++ Map.keys(embedded))}
  end

  def rels({:ok, res}), do: rels(res)
  def rels(err), do: err

  def follow(res, rel), do: follow(res, rel, [])
  def follow({:ok, res}, rel, params), do: follow(res, rel, params)
  def follow({:error, err}, _rel, _params), do: {:error, err}

  def follow(%Resource{_embedded: embeds} = res, "" <> rel, params) do
    if Map.has_key?(embeds, rel) do
      {:ok, Map.get(embeds, rel)}
    else
      case link(res, rel) do
        {:ok, link} -> follow(res, link, params)
        err -> err
      end
    end
  end

  def follow(%Resource{_url: prev_url}, %Link{href: href}, params) do
    expanded = UriTemplate.expand(href, params)
    merged = URI.merge(prev_url, expanded)

    # TODO: would be nice if UriTemplate removed unused query params
    remove_blank_query_params(merged) |> Remote.get()
  end

  defp remove_blank_query_params(%URI{query: nil} = uri), do: to_string(uri)

  defp remove_blank_query_params(%URI{query: query} = uri) do
    filtered =
      query
      |> URI.decode_query()
      |> Enum.reject(fn {_key, val} -> val == nil || val == "" end)
      |> Map.new()
      |> URI.encode_query()

    case filtered do
      "" -> Map.put(uri, :query, nil) |> to_string()
      _ -> Map.put(uri, :query, filtered) |> to_string()
    end
  end
end

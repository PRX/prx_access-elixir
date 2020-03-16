defmodule PrxClient.Resource do
  defstruct [:_status, :_url, :attributes, :_links, :_embedded]

  defmodule Link do
    defstruct [:href, :title, :profile, :count, templated: false]

    def from_json(json) do
      %PrxClient.Resource.Link{
        href: json["href"],
        title: json["title"],
        profile: json["profile"],
        templated: json["templated"] || false,
        count: json["count"]
      }
    end
  end

  def build(status, url, body) when status >= 200 and status < 300 do
    case Poison.decode(body) do
      {:ok, json} -> {:ok, from_json(status, url, json)}
      _not_json -> PrxClient.Error.build(status, url, body)
    end
  end

  def build(status, url, body), do: PrxClient.Error.build(status, url, body)

  def from_json(status, url, json) do
    %PrxClient.Resource{}
    |> Map.put(:_status, status)
    |> Map.put(:_url, url)
    |> Map.put(:attributes, parse_attributes(json))
    |> Map.put(:_links, parse_links(json))
    |> Map.put(:_embedded, parse_embedded(status, url, json))
  end

  defp parse_attributes(json) do
    Map.drop(json, ["_links", "_embedded"])
  end

  defp parse_links(json) do
    json
    |> Map.get("_links", %{})
    |> Enum.map(fn {key, link} -> {key, parse_link(link)} end)
    |> Map.new()
  end

  defp parse_link([]), do: []
  defp parse_link([link | rest]), do: [Link.from_json(link)] ++ parse_link(rest)
  defp parse_link(link), do: Link.from_json(link)

  defp parse_embedded(status, url, json) do
    json
    |> Map.get("_embedded", %{})
    |> Enum.map(fn {key, embed} -> {key, parse_embed(status, url, embed)} end)
    |> Map.new()
  end

  defp parse_embed(_status, _url, []), do: []

  defp parse_embed(status, url, [embed | rest]) do
    [from_json(status, url, embed)] ++ parse_embed(status, url, rest)
  end

  defp parse_embed(status, url, embed), do: from_json(status, url, embed)
end

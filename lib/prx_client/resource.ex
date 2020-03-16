defmodule PrxClient.Resource do
  defstruct [:attributes, :_links, :_embedded, :_url, :_status]

  defmodule Link do
    defstruct [:href, :title, :profile, :templated, :count]

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

  def from_json(json) do
    %PrxClient.Resource{}
    |> Map.put(:attributes, parse_attributes(json))
    |> Map.put(:_links, parse_links(json))
    |> Map.put(:_embedded, parse_embedded(json))
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

  defp parse_embedded(json) do
    Map.get(json, "_embedded", %{})
  end
end

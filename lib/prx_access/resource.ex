defmodule PrxAccess.Resource do
  @behaviour Access
  @resource_keys [:_status, :_url, :_token, :attributes, :_links, :_embedded]
  defstruct [:_status, :_url, :_token, :attributes, :_links, :_embedded]

  defmodule Link do
    @behaviour Access
    @link_aliases %{
      "href" => :href,
      "title" => :title,
      "profile" => :profile,
      "count" => :count,
      "templated" => :templated
    }
    defstruct [:href, :title, :profile, :count, templated: false]

    def link_alias(key), do: Map.get(@link_aliases, key, key)
    def fetch(link, key), do: Map.fetch(link, link_alias(key))
    def get_and_update(link, key, func), do: Map.get_and_update(link, link_alias(key), func)
    def pop(link, key), do: Map.pop(link, link_alias(key))

    def from_json(json) do
      %PrxAccess.Resource.Link{
        href: json["href"],
        title: json["title"],
        profile: json["profile"],
        templated: json["templated"] || false,
        count: json["count"]
      }
    end
  end

  def fetch(res, key) do
    cond do
      Enum.member?(@resource_keys, key) -> Map.fetch(res, key)
      key == "_links" -> Map.fetch(res, :_links)
      key == "_embedded" -> Map.fetch(res, :_embedded)
      true -> Map.fetch(res.attributes || %{}, key)
    end
  end

  def get_and_update(res, key, func),
    do: Map.put(res, :attributes, Map.get_and_update(res.attributes || %{}, key, func))

  def pop(res, key), do: Map.put(res, :attributes, Map.pop(res.attributes || %{}, key))

  def build(status, url, body), do: build(status, url, nil, body)

  def build(status, url, token, body) when status >= 200 and status < 300 do
    case Poison.decode(body) do
      {:ok, json} -> {:ok, from_json(status, url, token, json)}
      _not_json -> PrxAccess.Error.build(status, url, body)
    end
  end

  def build(status, url, _token, body), do: PrxAccess.Error.build(status, url, body)

  def from_json(status, url, token, json) do
    %PrxAccess.Resource{}
    |> Map.put(:_status, status)
    |> Map.put(:_url, url)
    |> Map.put(:_token, token)
    |> Map.put(:attributes, parse_attributes(json))
    |> Map.put(:_links, parse_links(json))
    |> Map.put(:_embedded, parse_embedded(status, url, token, json))
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

  defp parse_embedded(status, url, token, json) do
    json
    |> Map.get("_embedded", %{})
    |> Enum.map(fn {key, embed} -> {key, parse_embed(status, url, token, embed)} end)
    |> Map.new()
  end

  defp parse_embed(_status, _url, _token, []), do: []

  defp parse_embed(status, url, token, [embed | rest]) do
    [from_json(status, url, token, embed)] ++ parse_embed(status, url, token, rest)
  end

  defp parse_embed(status, url, token, embed), do: from_json(status, url, token, embed)
end

defmodule PrxClient.Factory do
  use ExMachina

  import Mox

  def root_json_factory do
    %{"foo" => "bar"}
  end

  def root_response_factory(attrs) do
    {:ok, json} = build(:root_json, Map.get(attrs, :json, %{})) |> Poison.encode()
    resp = %HTTPoison.Response{status_code: 200, body: json}
    merge_attributes(resp, Map.delete(attrs, :json))
  end

  def mock_root_factory(attrs) do
    resp = build(:root_response, attrs)
    expect(Dovetail.MockHTTPoison, :get, fn _url, _hdrs -> {:ok, resp} end)
    resp
  end

  def resource_factory do
    %PrxClient.Resource{
      attributes: %{"foo" => "bar"},
      _links: %{
        "profile" => %PrxClient.Resource.Link{href: "/api/v1/thing/1234"},
        "prx:others" => [%PrxClient.Resource.Link{href: "/api/v1/other/5678"}]
      },
      _embedded: %{
        "prx:items" => []
      },
      _url: "https://host.prx.org/api/v1/thing/1234",
      _status: 200
    }
  end
end

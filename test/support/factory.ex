defmodule PrxClient.Factory do
  use ExMachina

  alias PrxClient.Resource
  alias PrxClient.Resource.Link

  def resource_json_factory do
    %{
      id: 1234,
      title: "resource json",
      createdAt: "2020-03-13T20:45:58.414Z",
      updatedAt: "2020-03-13T20:48:13.427Z",
      _links: %{
        self: %{
          href: "/api/v1/",
          profile: "http://meta.prx.org/model/api"
        },
        profile: %{
          href: "http://meta.prx.org/model/api"
        },
        "prx:something": %{
          title: "Get a single something",
          profile: "http://meta.prx.org/model/something",
          href: "/api/v1/somethings/{id}{?zoom}",
          templated: true
        },
        "prx:somethings": %{
          title: "Get a paged collection of somethings",
          profile: "http://meta.prx.org/model/collection/something",
          href: "/api/v1/somethings{?page,per,zoom}",
          templated: true
        }
      }
    }
  end

  def fake_response_factory(attrs) do
    body = Map.get(attrs, :body, build(:resource_json, attrs))
    resp = FakeServer.Response.ok!(body)
    merge_attributes(resp, Map.delete(attrs, :body))
  end

  def resource_factory do
    %Resource{
      attributes: %{"foo" => "bar"},
      _links: %{
        "profile" => %Link{href: "http://meta.prx.org/model/something"},
        "prx:somethings" => [
          %Link{href: "/api/v1/somethings{?page,per}", templated: true}
        ]
      },
      _embedded: %{
        "prx:items" => [
          %Resource{attributes: %{"id" => "one"}},
          %Resource{attributes: %{"id" => "two"}}
        ]
      },
      _url: "https://host.prx.org/api/v1/thing/1234",
      _status: 200
    }
  end
end

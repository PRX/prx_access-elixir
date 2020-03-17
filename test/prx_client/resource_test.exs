defmodule PrxClient.ResourceTest do
  use ExUnit.Case, async: true

  alias PrxClient.Resource
  alias PrxClient.Error

  test "has fields" do
    res = %Resource{}
    assert res._status == nil
    assert res._url == nil
    assert res._token == nil
    assert res.attributes == nil
    assert res._links == nil
    assert res._embedded == nil
  end

  test "builds from json" do
    {:ok, res} = Resource.build(200, "http://some.where", "{\"foo\":\"bar\"}")
    assert %Resource{} = res
    assert res._status == 200
    assert res._url == "http://some.where"
    assert res.attributes == %{"foo" => "bar"}
    assert res._links == %{}
    assert res._embedded == %{}
  end

  test "builds with a token" do
    {:ok, res} = Resource.build(200, nil, "my-token", "{}")
    assert %Resource{} = res
    assert res._token == "my-token"
  end

  test "handles json decode errors" do
    {:error, err} = Resource.build(200, "http://some.where", "bad-json")
    assert %Error{} = err
    assert err.status == 200
    assert err.url == "http://some.where"
    assert err.message == "JSON decode error: bad-json"
    assert err.json == nil
  end

  test "handles non-2XX text errors" do
    {:error, err} = Resource.build(404, "http://some.where", "text error msg")
    assert %Error{} = err
    assert err.status == 404
    assert err.url == "http://some.where"
    assert err.message == "text error msg"
    assert err.json == nil
  end

  test "handles non-2XX json errors" do
    {:error, err} = Resource.build(500, "http://some.where", "{\"foo\":\"bar\"}")
    assert %Error{} = err
    assert err.status == 500
    assert err.url == "http://some.where"
    assert err.message == "Got 500 for http://some.where"
    assert err.json == %{"foo" => "bar"}
  end

  test "parses links" do
    {:ok, json} =
      Poison.encode(%{
        _links: %{
          "prx:link" => %{href: "my-href", title: "my-title", profile: "my-profile", count: 123}
        }
      })

    {:ok, res} = Resource.build(200, "http://some.where", json)
    assert %Resource{} = res

    assert res._links == %{
             "prx:link" => %Resource.Link{
               href: "my-href",
               title: "my-title",
               profile: "my-profile",
               templated: false,
               count: 123
             }
           }
  end

  test "parses embedded resources" do
    {:ok, json} =
      Poison.encode(%{
        _embedded: %{
          "prx:embed" => [
            %{id: "one"},
            %{id: "two", _links: %{"prx:link" => %{href: "embedded-link"}}}
          ]
        }
      })

    {:ok, res} = Resource.build(200, "http://some.where", "my-token", json)
    assert %Resource{} = res

    assert res._embedded == %{
             "prx:embed" => [
               %Resource{
                 _status: 200,
                 _url: "http://some.where",
                 _token: "my-token",
                 attributes: %{"id" => "one"},
                 _embedded: %{},
                 _links: %{}
               },
               %Resource{
                 _status: 200,
                 _url: "http://some.where",
                 _token: "my-token",
                 attributes: %{"id" => "two"},
                 _embedded: %{},
                 _links: %{
                   "prx:link" => %Resource.Link{href: "embedded-link"}
                 }
               }
             ]
           }
  end
end

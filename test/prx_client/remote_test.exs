defmodule PrxClient.RemoteTest do
  use ExUnit.Case, async: true

  import Mox
  import PrxClient.Factory

  alias PrxClient.Remote
  alias PrxClient.Resource
  alias PrxClient.Error

  setup :verify_on_exit!

  test "sets http headers" do
    expect(Dovetail.MockHTTPoison, :get, fn url, hdrs ->
      assert url == "http://some.where/api/v1"
      assert hdrs == [{"Accept", "application/hal+json"}]
      {:ok, %HTTPoison.Response{status_code: 200, body: "{}"}}
    end)

    assert {:ok, _res} = Remote.get("http://some.where/api/v1")
  end

  test "sets authorization headers" do
    expect(Dovetail.MockHTTPoison, :get, fn url, hdrs ->
      assert url == "http://some.where/api/v1"
      assert hdrs == [{"Accept", "application/hal+json"}, {"Authorization", "Bearer my-token"}]
      {:ok, %HTTPoison.Response{status_code: 200, body: "{}"}}
    end)

    assert {:ok, _res} = Remote.get("http://some.where/api/v1", "my-token")
  end

  test "gets resources" do
    build(:mock_http, body: "{\"foo\":\"bar\"}")
    assert {:ok, res} = Remote.get("http://some.where/api/v1")
    assert %Resource{} = res
    assert res._status == 200
    assert res._url == "http://some.where/api/v1"
    assert res.attributes == %{"foo" => "bar"}
  end

  test "gets errors" do
    build(:mock_http, body: "this-is-not-json")
    assert {:error, err} = Remote.get("http://some.where/api/v1")
    assert %Error{} = err
    assert err.message == "JSON decode error: this-is-not-json"
  end
end

defmodule PrxClient.RemoteTest do
  use ExUnit.Case

  import FakeServer
  import PrxClient.Factory

  alias PrxClient.Remote
  alias PrxClient.Resource
  alias PrxClient.Error

  test_with_server "sets http headers" do
    route("/api/v1", FakeServer.Response.ok("{}"))

    assert {:ok, _res} = Remote.get("http://#{FakeServer.address()}/api/v1")
    assert FakeServer.hits() == 1
    assert request_received("/api/v1", headers: %{"accept" => "application/hal+json"})
  end

  test_with_server "sets authorization headers" do
    route("/api/v1", FakeServer.Response.ok("{}"))

    assert {:ok, _res} = Remote.get("http://#{FakeServer.address()}/api/v1", "my-token")
    assert FakeServer.hits() == 1
    assert request_received("/api/v1", headers: %{"authorization" => "Bearer my-token"})
  end

  test_with_server "gets resources" do
    route("/api/v1/blah", build(:fake_response, body: "{\"foo\":\"bar\"}"))
    assert {:ok, res} = Remote.get("http://#{FakeServer.address()}/api/v1/blah")
    assert %Resource{} = res
    assert res._status == 200
    assert res._url == "http://#{FakeServer.address()}/api/v1/blah"
    assert res.attributes == %{"foo" => "bar"}
  end

  test_with_server "gets errors" do
    route("/api/v1/", build(:fake_response, body: "this-is-not-json"))
    assert {:error, err} = Remote.get("http://#{FakeServer.address()}/api/v1/")
    assert %Error{} = err
    assert err.message == "JSON decode error: this-is-not-json"
  end
end

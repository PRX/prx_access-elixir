defmodule PrxClient.ErrorTest do
  use ExUnit.Case, async: true

  alias PrxClient.Error

  test "has fields" do
    err = %Error{}
    assert err.status == nil
    assert err.url == nil
    assert err.message == nil
    assert err.json == nil
  end

  test "builds from bad json" do
    assert {:error, err} = Error.build(200, "http://some.where", "bad-json")
    assert %Error{} = err
    assert err.status == 200
    assert err.url == "http://some.where"
    assert err.message == "JSON decode error: bad-json"
    assert err.json == nil
  end

  test "builds from text" do
    assert {:error, err} = Error.build(500, "http://some.where", "non-json")
    assert %Error{} = err
    assert err.status == 500
    assert err.url == "http://some.where"
    assert err.message == "non-json"
    assert err.json == nil
  end

  test "builds from json" do
    assert {:error, err} = Error.build(404, "http://some.where", %{"my" => "json"})
    assert %Error{} = err
    assert err.status == 404
    assert err.url == "http://some.where"
    assert err.message == "Got 404 for http://some.where"
    assert err.json == %{"my" => "json"}
  end
end

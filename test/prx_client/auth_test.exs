defmodule PrxAccess.AuthTest do
  use ExUnit.Case, async: true

  import FakeServer
  import PrxAccess.Factory

  alias PrxAccess.Auth
  alias PrxAccess.Error

  test "returns tokens if one already exists" do
    assert Auth.get_token(%{token: "1234"}) == {:ok, "1234"}
    assert Auth.get_token(%{token: "5678"}) == {:ok, "5678"}
  end

  test "returns nil if you don't ask for an account" do
    assert Auth.get_token(%{account: nil}) == {:ok, nil}
    assert Auth.get_token(%{account: []}) == {:ok, nil}
  end

  test "requires a client id and secret" do
    assert {:error, err} = Auth.get_token(%{account: 1234})
    assert %Error{} = err
    assert err.status == 401
    assert err.url == nil
    assert err.message == "Missing PrxAccess.Auth config: id, secret"
  end

  test_with_server "gets an oauth token" do
    route("/token", build(:token_response, account: 1234, id: "id", secret: "secret"))

    params = %{account: "1234", id: "id", secret: "secret", host: FakeServer.address()}
    assert {:ok, token} = Auth.get_token(params)
    assert token == "your-token-1234"
  end

  test_with_server "gets unauthorized errors" do
    unauth = build(:token_response, account: 1234, id: "id", secret: "secret", unauthorized: true)
    route("/token", unauth)

    params = %{account: "1234", id: "id", secret: "secret", host: FakeServer.address()}
    assert {:error, %Error{} = err} = Auth.get_token(params)
    assert err.status == 401
    assert err.url == "http://#{FakeServer.address()}/token"
    assert err.message == "Invalid credentials"
  end
end

#
#
#   assert {:ok, _res} = Remote.get("http://some.where/api/v1")
# end
#
# test "sets authorization headers" do
#   expect(PrxAccess.MockHTTPoison, :get, fn url, hdrs ->
#     assert url == "http://some.where/api/v1"
#     assert hdrs == [{"Accept", "application/hal+json"}, {"Authorization", "Bearer my-token"}]
#     {:ok, %HTTPoison.Response{status_code: 200, body: "{}"}}
#   end)

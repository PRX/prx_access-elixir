defmodule PrxAccess.Factory do
  use ExMachina

  alias PrxAccess.Resource
  alias PrxAccess.Resource.Link
  alias FakeServer.Response

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
    resp = Response.ok!(body)
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

  def token_response_factory(%{id: id, secret: secret} = attrs) do
    expected_form =
      %{
        "grant_type" => "client_credentials",
        "client_id" => id,
        "client_secret" => secret
      }
      |> form_optional_account(attrs[:account])
      |> form_optional_scope(attrs[:scope])
      |> URI.encode_query()

    plain_headers = %{"content-type" => "text/plain"}

    fn %{method: method, headers: %{"content-type" => type}, body: body} ->
      cond do
        method != "POST" ->
          Response.internal_server_error("bad method: #{method}", plain_headers)

        type != "application/x-www-form-urlencoded" ->
          Response.internal_server_error("bad content type: #{type}", plain_headers)

        body != expected_form ->
          Response.internal_server_error("bad form: #{body}", plain_headers)

        attrs[:unauthorized] ->
          Response.unauthorized("Invalid credentials", plain_headers)

        true ->
          account = Map.get(attrs, :account, "default-account")
          scope = Map.get(attrs, :scope, "default-scope")
          Response.ok(%{access_token: "your-token/#{account}/#{scope}", token_type: "bearer"})
      end
    end
  end

  defp form_optional_account(form, nil), do: form
  defp form_optional_account(form, account), do: Map.put(form, "account", account)
  defp form_optional_scope(form, nil), do: form
  defp form_optional_scope(form, scope), do: Map.put(form, "scope", scope)
end

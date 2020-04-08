defmodule PrxAccess.Auth do
  @default_id_host "id.prx.org"
  @token_url "/token"

  # use token POST body vs auth header for sending client id/secret
  @scheme "request_body"

  alias PrxAccess.Error

  # you already have a token (TODO: refreshing)
  def get_token(%{token: "" <> token}), do: {:ok, token}

  # you don't need a token
  def get_token(%{id: nil}), do: {:ok, nil}
  def get_token(%{auth: false}), do: {:ok, nil}

  # translate a list of account-ids to a comma separated string
  def get_token(%{account: accounts} = opts) when is_list(accounts) do
    Map.put(opts, :account, Enum.join(accounts, ",")) |> get_token()
  end

  def get_token(opts) do
    new_client(opts) |> client_token(opts[:account], opts[:scope])
  end

  defp new_client(%{id: "" <> id, secret: "" <> secret, host: "" <> host}) do
    OAuth2.Client.new(
      serializers: %{"application/json" => Poison},
      strategy: OAuth2.Strategy.ClientCredentials,
      client_id: id,
      client_secret: secret,
      site: PrxAccess.Remote.host_to_url(host),
      token_url: @token_url
    )
  end

  defp new_client(%{id: "" <> _id, secret: "" <> _secret} = opts) do
    Map.put(opts, :host, @default_id_host) |> new_client()
  end

  defp new_client(_opts) do
    Error.build(401, nil, "Missing PrxAccess.Auth config: id, secret")
  end

  defp client_token(%OAuth2.Client{} = client, account, scope) do
    case OAuth2.Client.get_token(client, oauth_params(account, scope), oauth_headers()) do
      {:ok, %OAuth2.Client{token: %{access_token: token}}} ->
        {:ok, token}

      {:error, %OAuth2.Response{status_code: status, body: %{"Invalid credentials" => _}}} ->
        Error.build(status, "#{client.site}#{client.token_url}", "Invalid credentials")

      {:error, %OAuth2.Response{status_code: status, body: "" <> body}} ->
        Error.build(status, "#{client.site}#{client.token_url}", body)

      {:error, %OAuth2.Response{status_code: status, body: body}} ->
        Error.build(status, "#{client.site}#{client.token_url}", inspect(body))

      {:error, %OAuth2.Error{reason: reason}} ->
        Error.build(401, nil, reason)
    end
  end

  defp client_token(err, _account, _scope), do: err

  defp oauth_params(nil, nil), do: [auth_scheme: @scheme]
  defp oauth_params(account, nil), do: [account: account, auth_scheme: @scheme]
  defp oauth_params(nil, scope), do: [scope: scope, auth_scheme: @scheme]
  defp oauth_params(account, scope), do: [account: account, scope: scope, auth_scheme: @scheme]

  defp oauth_headers(), do: [{"User-Agent", PrxAccess.Remote.user_agent()}]
end

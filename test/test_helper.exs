# mock http requests
Mox.defmock(PrxClient.MockHTTPoison, for: HTTPoison.Base)
Application.put_env(:prx_client, :http_library, PrxClient.MockHTTPoison)

# load factory
{:ok, _} = Application.ensure_all_started(:ex_machina)

# now start
ExUnit.start()

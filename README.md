# PrxAccess

[![Hex.pm](https://img.shields.io/hexpm/v/prx_access.svg)](https://hex.pm/packages/prx_access)
[![Hex.pm](https://img.shields.io/hexpm/dw/prx_access.svg)](https://hex.pm/packages/prx_access)
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](LICENSE)

Elixir client library for accessing PRX [HAL](https://en.wikipedia.org/wiki/Hypertext_Application_Language) APIs.

## Installation

Add the package to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:prx_access, "~> 0.1.0"}
  ]
end
```

## Usage

To make requests against the a PRX API host, just provide the hostname and
start navigating:

```elixir
{:ok, root} = PrxAccess.root("feeder.prx.org")

# list link rels on this root document
{:ok, rels} = PrxAccess.rels(root)

# follow one of them!
{:ok, podcasts} = PrxAccess.follow(root, "prx:podcasts", page: 1, per: 1)
IO.puts(podcasts.attributes["count"])
IO.puts(podcasts.attributes["total"])

# get items from this page
{:ok, items} = PrxAccess.follow(podcasts, "prx:items")
Enum.each(items, fn(i) -> IO.puts(i.attributes["title"]) end)

# follow off an item - woh, we're in CMS now!
{:ok, account} = hd(items) |> PrxAccess.follow("prx:account")
IO.puts(podcasts._url) # https://feeder.prx.org/api/v1/podcasts?page=1&per=1
IO.puts(account._url) # https://cms.prx.org/api/v1/accounts/5678
```

### Authorization

To make an authorized request, you'll need a PRX client_id and client_secret
for [id.prx.org](https://github.com/PRX/id.prx.org).

```elixir
auth_options = [
  account: 1234,
  id_host: "id.staging.prx.tech",
  client_id: "my-client-id",
  client_secret: "my-client-secret"
]
{:ok, root} = PrxAccess.root("cms.staging.prx.tech", auth_options)

# or maybe you want the /api/v1/authorization entry point
{:ok, auth_root} = PrxAccess.follow("/api/v1/authorization")

# or go directly there
{:ok, auth_direct} = PrxAccess.get("https://cms.staging.prx.tech/api/v1/authorization", auth_options)
```

### Chaining Requests

It's easy to chain together a bunch of HAL links, using elixir pipes.  If any of
your resources return a non-200, you'll get a `%PrxAccess.Error{}` returned for
any subsequent link-follows:

```elixir
{:ok, podcast} = PrxAccess.root("feeder.prx.org")
  |> PrxAccess.follow("prx:podcast", id: 70)

# or an error
{:error, err} = PrxAccess.root("feeder.prx.org")
  |> PrxAccess.follow("prx:podcast", id: 70)
  |> PrxAccess.follow("prx:whatev")
  |> PrxAccess.follow("prx:these")
  |> PrxAccess.follow("prx:arenot")
  |> PrxAccess.follow("prx:called")

IO.inspect(err)
# %PrxAccess.Error{
#   status: 200,
#   url: "https://feeder.prx.org/api/v1/podcasts/70",
#   message: "rel prx:whatev not found"
# }
```

## License

[MIT License](LICENSE)

## Contributing

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

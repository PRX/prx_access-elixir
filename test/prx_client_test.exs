defmodule PrxClientTest do
  use ExUnit.Case, async: true

  import Mox

  describe "root" do
    test "returns the root resource" do
    end
  end

  # test "greets the world" do
  #   root = PrxClient.root("feeder.prx.org")
  #
  #   assert PrxClient.rels(root) == [
  #            "curies",
  #            "profile",
  #            "prx:episode",
  #            "prx:episodes",
  #            "prx:podcast",
  #            "prx:podcasts",
  #            "self"
  #          ]
  #
  #   assert PrxClient.links(root, "prx:podcasts") == [
  #            %PrxClient.Resource.Link{
  #              count: nil,
  #              href: "/api/v1/podcasts{?page,per,zoom}",
  #              profile: "http://meta.prx.org/model/collection/podcasts",
  #              templated: true,
  #              title: "Get a paged collection of podcasts"
  #            }
  #          ]
  #
  #   assert PrxClient.link(root, "prx:podcasts") ==
  #            {:ok,
  #             %PrxClient.Resource.Link{
  #               count: nil,
  #               href: "/api/v1/podcasts{?page,per,zoom}",
  #               profile: "http://meta.prx.org/model/collection/podcasts",
  #               templated: true,
  #               title: "Get a paged collection of podcasts"
  #             }}
  #
  #   result =
  #     root
  #     |> PrxClient.follow("prx:podcasts", per: 1)
  #     |> PrxClient.follow("prx:items")
  #     |> PrxClient.follow("foo:bar")
  #
  #   IO.inspect(result)
  #
  #   # IO.inspect(PrxClient.link(root, "prx:podcasts"))
  #
  #   # PrxClient.api(account: account).tap { |a| a.href = podcast.prx_uri }.get
  #
  #   # assert PrxClient.hello() == :world
  # end
end

defmodule PrxAccessTest do
  use ExUnit.Case, async: true

  import FakeServer
  import PrxAccess.Factory

  alias PrxAccess.Resource
  alias PrxAccess.Resource.Link
  alias PrxAccess.Error

  describe "root" do
    test_with_server "returns the root resource" do
      route("/api/v1/", build(:fake_response))
      assert {:ok, root} = PrxAccess.root(FakeServer.address())
      assert %Resource{} = root
      assert root.attributes["title"] == "resource json"
    end

    test_with_server "returns json http errors" do
      route("/api/v1/", FakeServer.Response.internal_server_error("{}"))
      assert {:error, err} = PrxAccess.root(FakeServer.address())
      assert %Error{} = err
      assert err.message == "Got 500 for http://#{FakeServer.address()}/api/v1"
    end
  end

  describe "links" do
    test "returns resource links" do
      res = build(:resource)

      {:ok, link} = PrxAccess.links(res, "profile")
      assert link == %Link{href: "http://meta.prx.org/model/something"}

      {:ok, links} = PrxAccess.links(res, "prx:somethings")
      assert links == [%Link{href: "/api/v1/somethings{?page,per}", templated: true}]

      {:error, %Error{} = err} = PrxAccess.links(res, "prx:dne")
      assert err.status == 200
      assert err.url == "https://host.prx.org/api/v1/thing/1234"
      assert err.message == "rel prx:dne not found"
    end

    test "handles tuples" do
      res = build(:resource)
      assert {:ok, %Link{} = link} = PrxAccess.links({:ok, res}, "profile")
      assert {:error, "blah"} = PrxAccess.links({:error, "blah"}, "profile")
    end
  end

  describe "link" do
    test "returns the first resource link" do
      res = build(:resource)

      {:ok, link} = PrxAccess.link(res, "profile")
      assert link == %Link{href: "http://meta.prx.org/model/something"}

      {:ok, link} = PrxAccess.link(res, "prx:somethings")
      assert link == %Link{href: "/api/v1/somethings{?page,per}", templated: true}

      {:error, %Error{} = err} = PrxAccess.links(res, "prx:dne")
      assert err.status == 200
      assert err.url == "https://host.prx.org/api/v1/thing/1234"
      assert err.message == "rel prx:dne not found"
    end

    test "handles tuples" do
      res = build(:resource)
      assert {:ok, %Link{} = link} = PrxAccess.link({:ok, res}, "prx:somethings")
      assert {:error, "blah"} = PrxAccess.link({:error, "blah"}, "profile")
    end
  end

  describe "link?" do
    test "checks if a link exists" do
      res = build(:resource)
      assert PrxAccess.link?(res, "profile") == true
      assert PrxAccess.link?(res, "prx:somethings") == true
      assert PrxAccess.link?(res, "prx:dne") == false
    end

    test "handles tuples" do
      res = build(:resource)
      assert PrxAccess.link?({:ok, res}, "prx:somethings") == true
      assert PrxAccess.link?({:error, "blah"}, "profile") == false
    end
  end

  describe "rels" do
    test "returns both link and embedded rels" do
      res = build(:resource)
      assert PrxAccess.rels(res) == {:ok, ["profile", "prx:somethings", "prx:items"]}
    end

    test "handles tuples" do
      res = build(:resource)
      assert PrxAccess.rels({:ok, res}) == {:ok, ["profile", "prx:somethings", "prx:items"]}
      assert PrxAccess.rels({:error, "blah"}) == {:error, "blah"}
    end
  end

  describe "follow" do
    test_with_server "follows linked resources" do
      route("/api/v1", build(:fake_response))

      route("/api/v1/somethings", fn %{query: %{"page" => "4"}} ->
        build(:fake_response)
      end)

      assert {:ok, root} = PrxAccess.root(FakeServer.address())
      assert {:ok, res} = PrxAccess.follow(root, "prx:somethings", page: 4)
      assert %Resource{} = res
      assert res.attributes["id"] == 1234

      assert request_received("/api/v1")
      assert request_received("/api/v1/somethings")
    end

    test_with_server "removes unused query params" do
      route("/api/v1", build(:fake_response))

      route("/api/v1/somethings", fn %{query: %{}} ->
        build(:fake_response)
      end)

      assert {:ok, root} = PrxAccess.root(FakeServer.address())
      assert {:ok, res} = PrxAccess.follow(root, "prx:somethings")
      assert %Resource{} = res
      assert res.attributes["id"] == 1234

      assert request_received("/api/v1")
      assert request_received("/api/v1/somethings")
    end

    test "follows embedded resources" do
      assert {:ok, items} = PrxAccess.follow(build(:resource), "prx:items")
      assert length(items) == 2
      assert Enum.at(items, 0) == %Resource{attributes: %{"id" => "one"}}
      assert Enum.at(items, 1) == %Resource{attributes: %{"id" => "two"}}
    end

    test_with_server "handles tuples" do
      route("/api/v1", build(:fake_response))

      route("/api/v1/somethings", fn %{query: %{}} ->
        build(:fake_response)
      end)

      assert okay_root = PrxAccess.root(FakeServer.address())
      assert {:ok, res} = PrxAccess.follow(okay_root, "prx:somethings", page: 1, per: 2)
      assert %Resource{} = res
      assert res.attributes["id"] == 1234

      assert request_received("/api/v1")
      assert request_received("/api/v1/somethings")

      assert {:error, "blah"} = PrxAccess.follow({:error, "blah"}, "prx:somethings")
    end
  end
end

defmodule Scrivener.HTML.ParseTest do
  use ExUnit.Case
  import Scrivener.HTML.Parse, only: [parse: 2]
  import Phoenix.HTML, only: [raw: 1]
  alias Scrivener.Page

  doctest Scrivener.HTML.Parse

  @options [next: false, prev: false, first?: false, last?: false]

  def pages(range), do: Enum.to_list(range) |> Enum.map(&{&1, &1})

  def pages_with_first({first, num}, range),
    do: [{first, num}, {:ellipsis, Phoenix.HTML.raw("&hellip;")}] ++ pages(range)

  def pages_with_first(first, range),
    do: [{first, first}, {:ellipsis, Phoenix.HTML.raw("&hellip;")}] ++ pages(range)

  def pages_with_last({last, num}, range),
    do: pages(range) ++ [{:ellipsis, Phoenix.HTML.raw("&hellip;")}, {last, num}]

  def pages_with_last(last, range),
    do: pages(range) ++ [{:ellipsis, Phoenix.HTML.raw("&hellip;")}, {last, last}]

  def pages_with_next(range, next), do: pages(range) ++ [{">>", next}]
  def pages_with_prev(prev, range), do: [{"<<", prev}] ++ pages(range)

  describe "disable all options" do
    test "left out + right in" do
      assert pages(1..5) ==
               parse(%Page{total_pages: 100, page_number: -1}, @options)
    end

    test "left in + right in" do
      assert pages(48..52) ==
               parse(%Page{total_pages: 100, page_number: 50}, @options)
    end

    test "left in + right out" do
      assert pages(96..100) ==
               parse(%Page{total_pages: 100, page_number: 99}, @options)
    end

    test "left out + right out" do
      assert pages(96..100) ==
               parse(%Page{total_pages: 100, page_number: 101}, @options)
    end

    test "pages less than range" do
      assert pages(1..3) ==
               parse(%Page{total_pages: 3, page_number: 1}, @options)
    end
  end

  describe "option - :range" do
    test "change the range" do
      assert pages(49..51) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, range: 3)
               )
    end

    test "fallback to range 3" do
      assert pages(49..51) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, range: 1)
               )
    end
  end

  describe "option - :first" do
    test "add first" do
      assert pages_with_first(1, 49..52) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, first?: true)
               )
    end

    test "already include first" do
      assert pages(1..5) ==
               parse(
                 %Page{total_pages: 100, page_number: 3},
                 Keyword.merge(@options, first?: true)
               )
    end
  end

  describe "option - :last" do
    test "add last" do
      assert pages_with_last(100, 48..51) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, last?: true)
               )
    end

    test "already include last" do
      assert pages(96..100) ==
               parse(
                 %Page{total_pages: 100, page_number: 99},
                 Keyword.merge(@options, last?: true)
               )
    end
  end

  describe "option - :ellipsis" do
    test "custom ellipsis" do
      assert [
        {1, 1},
        {:ellipsis, "..."},
        {49, 49},
        {50, 50},
        {51, 51},
        {:ellipsis, "..."},
        {100, 100}
      ]

      parse(
        %Page{total_pages: 100, page_number: 50},
        Keyword.merge(@options, first?: true, last?: true, ellipsis: "...")
      )
    end
  end

  describe "option - :prev" do
    test "includes a prev" do
      assert pages_with_prev(49, 48..52) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, prev: "<<")
               )
    end

    test "does not include prev when page_number is 1" do
      assert pages(1..5) ==
               parse(
                 %Page{total_pages: 100, page_number: 1},
                 Keyword.merge(@options, prev: "<<")
               )
    end

    test "disable prev" do
      assert pages(48..52) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, prev: false)
               )
    end

    test "includes a prev before the first" do
      assert [{"<<", 49}, {1, 1}, {:ellipsis, raw("&hellip;")}] ++ pages(49..52) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, prev: "<<", first?: true)
               )
    end
  end

  describe "option - :next" do
    test "includes a next" do
      assert pages_with_next(48..52, 51) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, next: ">>")
               )
    end

    test "does not include prev when page_number equals to total_pages" do
      assert pages(96..100) ==
               parse(
                 %Page{total_pages: 100, page_number: 100},
                 Keyword.merge(@options, next: ">>")
               )
    end

    test "disable next" do
      assert pages(48..52) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, next: false)
               )
    end
  end
end

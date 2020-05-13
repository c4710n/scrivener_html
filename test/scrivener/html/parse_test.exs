defmodule Scrivener.HTML.ParseTest do
  use ExUnit.Case
  import Scrivener.HTML.Parse, only: [parse: 2]
  alias Scrivener.Page

  doctest Scrivener.HTML.Parse

  @options [next: false, previous: false, first: false, last: false]

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
  def pages_with_previous(previous, range), do: [{"<<", previous}] ++ pages(range)

  describe "disable all options" do
    test "in the middle" do
      assert pages(45..55) ==
               parse(%Page{total_pages: 100, page_number: 50}, @options)
    end

    test ":distance from the first" do
      assert pages(1..10) ==
               parse(%Page{total_pages: 20, page_number: 5}, @options)
    end

    test "2 away from the first" do
      assert pages(1..8) ==
               parse(%Page{total_pages: 10, page_number: 3}, @options)
    end

    test "1 away from the first" do
      assert pages(1..7) ==
               parse(%Page{total_pages: 10, page_number: 2}, @options)
    end

    test "at the first" do
      assert pages(1..6) ==
               parse(%Page{total_pages: 10, page_number: 1}, @options)
    end

    test ":distance from the last" do
      assert pages(10..20) ==
               parse(%Page{total_pages: 20, page_number: 15}, @options)
    end

    test "2 away from the last" do
      assert pages(3..10) ==
               parse(%Page{total_pages: 10, page_number: 8}, @options)
    end

    test "1 away from the last" do
      assert pages(4..10) ==
               parse(%Page{total_pages: 10, page_number: 9}, @options)
    end

    test "at the last" do
      assert pages(5..10) ==
               parse(%Page{total_pages: 10, page_number: 10}, @options)
    end

    test "page value larger than total pages" do
      assert pages(5..10) ==
               parse(%Page{total_pages: 10, page_number: 100}, @options)
    end
  end

  describe "option - :distance" do
    test "can change the distance" do
      assert pages(1..3) ==
               parse(
                 %Page{total_pages: 3, page_number: 2},
                 Keyword.merge(@options, distance: 1)
               )
    end
  end

  describe "option - :first" do
    test "includes the first" do
      assert pages_with_first(1, 5..15) ==
               parse(
                 %Page{total_pages: 20, page_number: 10},
                 Keyword.merge(@options, first: true)
               )
    end

    test "does not the include the first when it is already included" do
      assert pages(1..10) ==
               parse(
                 %Page{total_pages: 10, page_number: 5},
                 Keyword.merge(@options, first: true)
               )
    end

    test "custom" do
      assert pages_with_first({"←", 1}, 5..15) ==
               parse(
                 %Page{total_pages: 20, page_number: 10},
                 Keyword.merge(@options, first: "←")
               )
    end

    test "can disable first" do
      assert pages(5..15) ==
               parse(
                 %Page{total_pages: 20, page_number: 10},
                 Keyword.merge(@options, first: false)
               )
    end
  end

  describe "option - :last" do
    test "includes the last" do
      assert pages_with_last(20, 5..15) ==
               parse(
                 %Page{total_pages: 20, page_number: 10},
                 Keyword.merge(@options, last: true)
               )
    end

    test "does not the include the last when it is already included" do
      assert pages(1..10) ==
               parse(
                 %Page{total_pages: 10, page_number: 5},
                 Keyword.merge(@options, last: true)
               )
    end

    test "custom" do
      assert pages_with_last({"→", 20}, 5..15) ==
               parse(
                 %Page{total_pages: 20, page_number: 10},
                 Keyword.merge(@options, last: "→")
               )
    end

    test "can disable last" do
      assert pages(5..15) ==
               parse(
                 %Page{total_pages: 20, page_number: 10},
                 Keyword.merge(@options, last: false)
               )
    end
  end

  describe "option - :next" do
    test "includes a next" do
      assert pages_with_next(45..55, 51) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, next: ">>")
               )
    end

    test "does not include next when equal to the total" do
      assert pages(5..10) ==
               parse(
                 %Page{total_pages: 10, page_number: 10},
                 Keyword.merge(@options, next: ">>")
               )
    end

    test "can disable next" do
      assert pages(45..55) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, next: false)
               )
    end
  end

  describe "option - :previous" do
    test "includes a previous" do
      assert pages_with_previous(49, 45..55) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, previous: "<<")
               )
    end

    test "includes a previous before the first" do
      assert [{"<<", 49}, {1, 1}, {:ellipsis, Phoenix.HTML.raw("&hellip;")}] ++ pages(45..55) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, previous: "<<", first: true)
               )
    end

    test "does not include previous when equal to page 1" do
      assert pages(1..6) ==
               parse(
                 %Page{total_pages: 10, page_number: 1},
                 Keyword.merge(@options, previous: "<<")
               )
    end

    test "can disable previous" do
      assert pages(45..55) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, previous: false)
               )
    end
  end

  describe "option - :ellipsis" do
    test "includes ellipsis after first" do
      assert [{1, 1}, {:ellipsis, "&hellip;"}] ++ pages(45..55) ==
               parse(
                 %Page{total_pages: 100, page_number: 50},
                 Keyword.merge(@options, previous: false, first: true, ellipsis: "&hellip;")
               )
    end

    test "includes ellipsis before last" do
      assert pages(5..15) ++ [{:ellipsis, "&hellip;"}, {20, 20}] ==
               parse(
                 %Page{total_pages: 20, page_number: 10},
                 Keyword.merge(@options, last: true, ellipsis: "&hellip;")
               )
    end

    test "does not include ellipsis on first page" do
      assert pages(1..6) ==
               parse(
                 %Page{total_pages: 8, page_number: 1},
                 Keyword.merge(@options, first: true, ellipsis: "&hellip;")
               )
    end

    test "uses ellipsis only beyond <distance> of first page" do
      assert pages(1..11) ==
               parse(
                 %Page{total_pages: 20, page_number: 6},
                 Keyword.merge(@options, first: true, ellipsis: "&hellip;")
               )

      assert [{1, 1}] ++ pages(2..12) ==
               parse(
                 %Page{total_pages: 20, page_number: 7},
                 Keyword.merge(@options, first: true, ellipsis: "&hellip;")
               )
    end

    test "when first/last are true, uses ellipsis only when (<distance> + 1) is greater than the total pages" do
      options = [first: true, last: true, distance: 1]

      assert pages(1..3) ==
               parse(
                 %Page{total_pages: 3, page_number: 1},
                 Keyword.merge(@options, options)
               )

      assert pages(1..3) ==
               parse(
                 %Page{total_pages: 3, page_number: 3},
                 Keyword.merge(@options, options)
               )
    end

    test "does not include ellipsis on last page" do
      assert pages(15..20) ==
               parse(
                 %Page{total_pages: 20, page_number: 20},
                 Keyword.merge(@options,
                   last: true,
                   ellipsis: "&hellip;"
                 )
               )
    end

    test "uses ellipsis only beyond <distance> of last page" do
      options = [last: true, ellipsis: "&hellip;"]

      assert pages(10..20) ==
               parse(
                 %Page{total_pages: 20, page_number: 15},
                 Keyword.merge(@options, options)
               )

      assert pages(9..19) ++ [{20, 20}] ==
               parse(
                 %Page{total_pages: 20, page_number: 14},
                 Keyword.merge(@options, options)
               )
    end
  end
end

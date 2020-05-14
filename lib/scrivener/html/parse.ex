defmodule Scrivener.HTML.Parse do
  import Scrivener.HTML.Helper, only: [fetch_options: 2, clamp: 3]
  require Integer
  alias Scrivener.Page

  @defaults [
    range: 5,
    prev: "PREV",
    next: "NEXT",
    first?: true,
    last?: true,
    ellipsis: {:safe, "&hellip;"}
  ]

  @doc """
  Returns the raw data in order to generate the proper HTML for pagination.

  ## Default options
  Default options are supplied as following:

  ```
  #{inspect(@defaults)}
  ```

  + `range` declares how many pages are shown. It is a positive integer.
  + `prev` and `next` declares text for previous and next buttons. Generally,
  they are string. Falsy values will remove them from output.
  + `first?` and `last?` declares whether show first or last page.

  ## Return value
  Return value is a list of tuples. The tuple is in a `{text, page_number}` format
  where `text` is intended to be the text of the link and `page_number` is the
  page number it should go to.

  ## Examples

      iex> parse(%Scrivener.Page{total_pages: 10, page_number: 5}, [])
      [
        {"<<", 4},
        {1, 1},
        {2, 2},
        {3, 3},
        {4, 4},
        {5, 5},
        {6, 6},
        {7, 7},
        {8, 8},
        {9, 9},
        {10, 10},
        {">>", 6}
      ]

      iex> parse(%Scrivener.Page{total_pages: 15, page_number: 8}, first: "←", last: "→")
      [
        {"<<", 7},
        {"←", 1},
        {:ellipsis, {:safe, "&hellip;"}},
        {3, 3},
        {4, 4},
        {5, 5},
        {6, 6},
        {7, 7},
        {8, 8},
        {9, 9},
        {10, 10},
        {11, 11},
        {12, 12},
        {13, 13},
        {:ellipsis, {:safe, "&hellip;"}},
        {"→", 15},
        {">>", 9}
      ]

  """
  def parse(%Page{} = page, options \\ []) do
    %{page_number: page_number, total_pages: total_pages} = page

    options = fetch_options(options, @defaults)
    opt_range = options[:range]
    opt_prev = options[:prev]
    opt_next = options[:next]
    opt_first = options[:first?]
    opt_last = options[:last?]
    opt_ellipsis = options[:ellipsis]

    {left_distance, right_distance} = get_distance(opt_range)

    page_number = clamp(page_number, 1, total_pages)

    []
    |> get_pages(page_number, total_pages, opt_range, left_distance, right_distance)
    |> add_first(opt_first, opt_ellipsis)
    |> add_last(opt_last, opt_ellipsis, total_pages)
    |> add_prev(page_number)
    |> add_next(page_number, total_pages)
    |> Enum.map(fn
      :prev ->
        {opt_prev, page_number - 1}

      :next ->
        {opt_next, page_number + 1}

      :ellipsis ->
        {:ellipsis, opt_ellipsis}

      :first ->
        {1, 1}

      :last ->
        {total_pages, total_pages}

      num when is_number(num) ->
        {num, num}
    end)
  end

  # computer page number ranges
  defp get_pages(list, page_number, total_pages, range, left_distance, right_distance) do
    page_range = get_page_range(page_number, total_pages, range, left_distance, right_distance)
    list ++ Enum.to_list(page_range)
  end

  # left out + right out / left out + right in
  def get_page_range(page_number, total_pages, range, left_distance, right_distance)
      when page_number - left_distance < 1 do
    1..min(range, total_pages)
  end

  # left in + right in
  def get_page_range(page_number, total_pages, range, left_distance, right_distance)
      when page_number - left_distance >= 1 and
             page_number + right_distance <= total_pages do
    (page_number - left_distance)..(page_number + right_distance)
  end

  # left in + right out / left out + right out
  def get_page_range(page_number, total_pages, range, left_distance, right_distance)
      when page_number + right_distance > total_pages do
    max(total_pages - range + 1, 1)..total_pages
  end

  defp add_first(list, first, ellipsis) do
    [min_page_number | rest] = list

    cond do
      first && min_page_number > 1 ->
        [:first, :ellipsis] ++ rest

      min_page_number > 1 && ellipsis ->
        [:ellipsis] ++ list

      true ->
        list
    end
  end

  def add_last(list, last, ellipsis, total_pages) do
    {max_page_number, rest} = List.pop_at(list, -1)

    cond do
      last && max_page_number < total_pages ->
        rest ++ [:ellipsis, :last]

      ellipsis && max_page_number < total_pages ->
        list ++ [:ellipsis]

      true ->
        list
    end
  end

  defp add_prev(list, page_number)
       when page_number > 1 do
    [:prev | list]
  end

  defp add_prev(list, _page_number) do
    list
  end

  defp add_next(list, page_number, total_pages)
       when page_number < total_pages do
    list ++ [:next]
  end

  defp add_next(list, _page_number, _total_pages) do
    list
  end

  def get_distance(range) when Integer.is_odd(range) do
    left_distance = div(range, 2)
    right_distance = left_distance
    {left_distance, right_distance}
  end

  def get_distance(range) when Integer.is_even(range) do
    right_distance = div(range, 2)
    left_distance = right_distance - 1
    {left_distance, right_distance}
  end

  @doc """
  Return default options.
  """
  def defaults(), do: @defaults
end

defmodule Scrivener.HTML.Parse do
  import Scrivener.HTML.Helper, only: [fetch_options: 2]
  alias Scrivener.Page

  @defaults [
    distance: 5,
    previous: "<<",
    next: ">>",
    first: true,
    last: true,
    ellipsis: {:safe, "&hellip;"}
  ]

  @doc """
  Returns the raw data in order to generate the proper HTML for pagination.

  ## Default options
  Default options are supplied as following:

  ```
  #{inspect(@defaults)}
  ```

  + `distance` declares how many pages are shown. It is a positive integer.
  + `previous` and `next` declares text for previous and next buttons. Generally,
  they are string. Falsy values will remove them from output.
  + `first` and `last` declares whether show first or last page. Genrally, they are
  boolean values, but they can be strings, too.

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
    opt_distance = options[:distance]
    opt_previous = options[:previous]
    opt_next = options[:next]
    opt_first = options[:first]
    opt_last = options[:last]
    opt_ellipsis = options[:ellipsis]

    []
    |> add_first(page_number, opt_distance, opt_first)
    |> add_first_ellipsis(page_number, total_pages, opt_distance, opt_first)
    |> add_previous(page_number)
    |> page_number_list(page_number, total_pages, opt_distance)
    |> add_last_ellipsis(page_number, total_pages, opt_distance, opt_last)
    |> add_last(page_number, total_pages, opt_distance, opt_last)
    |> add_next(page_number, total_pages)
    |> Enum.map(fn
      :previous ->
        if opt_previous, do: {opt_previous, page_number - 1}

      :next ->
        if opt_next, do: {opt_next, page_number + 1}

      :first_ellipsis ->
        if opt_ellipsis && opt_first, do: {:ellipsis, opt_ellipsis}

      :last_ellipsis ->
        if opt_ellipsis && opt_last, do: {:ellipsis, opt_ellipsis}

      :first ->
        if opt_first, do: {opt_first, 1}

      :last ->
        if opt_last, do: {opt_last, total_pages}

      num when is_number(num) ->
        {num, num}
    end)
    |> Enum.filter(& &1)
  end

  # Computing page number ranges
  defp page_number_list(list, page_number, total_pages, distance)
       when is_integer(distance) and distance >= 1 do
    list ++
      Enum.to_list(
        beginning_distance(page_number, total_pages, distance)..end_distance(
          page_number,
          total_pages,
          distance
        )
      )
  end

  defp page_number_list(_list, _page_number, _total_pages, _distance) do
    raise "Scrivener.HTML: Distance cannot be less than one."
  end

  # Beginning distance computation
  # For low page numbers
  defp beginning_distance(page_number, _total_pages, distance)
       when page_number - distance < 1 do
    page_number - (distance + (page_number - distance - 1))
  end

  # For medium to high end page numbers
  defp beginning_distance(page_number, total_pages, distance)
       when page_number <= total_pages do
    page_number - distance
  end

  # For page numbers over the total number of pages
  # (prevent DOS attack generating too many pages)
  defp beginning_distance(page_number, total_pages, distance)
       when page_number > total_pages do
    total_pages - distance
  end

  # End distance computation
  # For high end page numbers (prevent DOS attack generating too many pages)
  defp end_distance(page_number, total_pages, distance)
       when page_number + distance >= total_pages and total_pages != 0 do
    total_pages
  end

  # For when there is no pages, cannot trust page number because it is supplied
  # by user potentially (prevent DOS attack)
  defp end_distance(_page_number, 0, _distance) do
    1
  end

  # For low to mid range page numbers
  # (guard here to ensure crash if something goes wrong)
  defp end_distance(page_number, total_pages, distance)
       when page_number + distance < total_pages do
    page_number + distance
  end

  # Adding next/prev/first/last links
  defp add_previous(list, page_number) when page_number != 1 do
    [:previous | list]
  end

  defp add_previous(list, _page_number) do
    list
  end

  defp add_first(list, page_number, distance, true)
       when page_number - distance > 1 do
    [1 | list]
  end

  defp add_first(list, page_number, distance, first)
       when page_number - distance > 1 and first != false do
    [:first | list]
  end

  defp add_first(list, _page_number, _distance, _included) do
    list
  end

  defp add_last(list, page_number, total_pages, distance, true)
       when page_number + distance < total_pages do
    list ++ [total_pages]
  end

  defp add_last(list, page_number, total_pages, distance, last)
       when page_number + distance < total_pages and last != false do
    list ++ [:last]
  end

  defp add_last(list, _page_number, _total_pages, _distance, _included) do
    list
  end

  defp add_next(list, page_number, total_pages)
       when page_number != total_pages and page_number < total_pages do
    list ++ [:next]
  end

  defp add_next(list, _page_number, _total_pages) do
    list
  end

  defp add_first_ellipsis(list, page_number, total_pages, distance, true) do
    add_first_ellipsis(list, page_number, total_pages, distance + 1, nil)
  end

  defp add_first_ellipsis(list, page_number, _total_pages, distance, _first)
       when page_number - distance > 1 and page_number > 1 do
    list ++ [:first_ellipsis]
  end

  defp add_first_ellipsis(list, _page_number, _total_pages, _distance, _first) do
    list
  end

  defp add_last_ellipsis(list, page_number, total_pages, distance, true) do
    add_last_ellipsis(list, page_number, total_pages, distance + 1, nil)
  end

  defp add_last_ellipsis(list, page_number, total_pages, distance, _)
       when page_number + distance < total_pages and page_number != total_pages do
    list ++ [:last_ellipsis]
  end

  defp add_last_ellipsis(list, _page_number, _total_pages, _distance, _last) do
    list
  end

  @doc """
  Return default options.
  """
  def defaults(), do: @defaults
end

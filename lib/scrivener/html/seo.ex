defmodule Scrivener.HTML.SEO do
  import Phoenix.HTML.Tag, only: [tag: 2]
  import Scrivener.HTML.Helper, only: [fetch_options: 2]
  alias Scrivener.Page

  @defaults Scrivener.HTML.defaults()

  @moduledoc """
  SEO related functions for pagination.

  See [Indicating paginated content to Google](https://web.archive.org/web/20190217083902/https://support.google.com/webmasters/answer/1663744?hl=en)
  for more information.
  """

  @doc """
  Produces the value for a `rel` attribute in an `<a>` tag. Returns either
  `"next"`, `"prev"` or `"canonical"`.

      iex> Scrivener.HTML.SEO.rel(%Scrivener.Page{page_number: 5}, 4)
      "prev"

      iex> Scrivener.HTML.SEO.rel(%Scrivener.Page{page_number: 5}, 6)
      "next"

      iex> Scrivener.HTML.SEO.rel(%Scrivener.Page{page_number: 5}, 8)
      "canonical"

  `Scrivener.HTML.pagination/2` will use this module to add `rel` attribute to
  each link.
  """
  def rel(%Page{page_number: current_page}, page_number)
      when current_page + 1 == page_number,
      do: "next"

  def rel(%Page{page_number: current_page}, page_number)
      when current_page - 1 == page_number,
      do: "prev"

  def rel(_page, _page_number), do: "canonical"

  @doc ~S"""
  Produces `<link/>` tags for putting in the `<head>` to help SEO.

  The arguments passed in are the same as `Scrivener.HTML.pagination/2`.

  See [SEO Tags in Phoenix](http://blog.danielberkompas.com/2016/01/28/seo-tags-in-phoenix.html)
  to know about how to do that.

      iex> Scrivener.HTML.SEO.header_links(%Scrivener.Page{total_pages: 10, page_number: 3}) |> Phoenix.HTML.safe_to_string
      "<link href=\"?page=2\" rel=\"prev\">\n<link href=\"?page=4\" rel=\"next\">"

  """
  def header_links(page, opts \\ [])

  def header_links(%Page{page_number: 1} = page, opts) do
    next_header_link(page, opts)
  end

  def header_links(
        %Page{total_pages: page_number, page_number: page_number} = page,
        opts
      ) do
    prev_header_link(page, opts)
  end

  def header_links(%Page{} = page, opts) do
    {:safe, prev} = prev_header_link(page, opts)
    {:safe, next} = next_header_link(page, opts)
    {:safe, [prev, "\n", next]}
  end

  defp href(_page, opts, page_number) do
    options = fetch_options(opts, @defaults)
    path = options[:path]
    page_param = options[:page_param]
    url_params = Keyword.drop(opts, Keyword.keys(@defaults))

    params =
      case page_number > 1 do
        true -> [{page_param, page_number}]
        false -> []
      end ++ url_params

    query = URI.encode_query(params)

    "#{path}?#{query}"
  end

  defp prev_header_link(page, opts) do
    page_number = page.page_number - 1
    href = href(page, opts, page_number)
    tag(:link, href: href, rel: rel(page, page_number))
  end

  defp next_header_link(page, opts) do
    page_number = page.page_number + 1
    href = href(page, opts, page_number)
    tag(:link, href: href, rel: rel(page, page_number))
  end
end

defmodule Scrivener.HTML.RenderTest do
  use ExUnit.Case
  import Scrivener.HTML.Render, only: [render: 3]
  alias Scrivener.Page

  doctest Scrivener.HTML.Render

  def compress_html(html) do
    html
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(fn i -> String.length(i) > 0 end)
    |> Enum.join()
  end

  @page %Page{total_pages: 15, page_number: 7}

  @parsed [
    {"PREV", 6},
    {1, 1},
    {:ellipsis, {:safe, "&hellip;"}},
    {6, 6},
    {7, 7},
    {8, 8},
    {:ellipsis, {:safe, "&hellip;"}},
    {15, 15},
    {"NEXT", 8}
  ]

  test "render without :html_attrs option" do
    rendered =
      render(@parsed, @page, path: "https://www.example.com") |> Phoenix.HTML.safe_to_string()

    expected = """
      <ul>
        <li><a href="https://www.example.com?page=6" rel="prev">PREV</a></li>
        <li><a href="https://www.example.com?" rel="canonical">1</a></li>
        <li><span>&hellip;</span></li>
        <li><a href="https://www.example.com?page=6" rel="prev">6</a></li>
        <li><a>7</a></li>
        <li><a href="https://www.example.com?page=8" rel="next">8</a></li>
        <li><span>&hellip;</span></li>
        <li><a href="https://www.example.com?page=15" rel="canonical">15</a></li>
        <li><a href="https://www.example.com?page=8" rel="next">NEXT</a></li>
      </ul>
    """

    assert rendered == compress_html(expected)
  end

  test "render with :html_attrs option" do
    rendered =
      render(@parsed, @page, path: "https://www.example.com", html_attrs: [class: "pagination"])
      |> Phoenix.HTML.safe_to_string()

    expected = """
      <ul class="pagination">
        <li><a href="https://www.example.com?page=6" rel="prev">PREV</a></li>
        <li><a href="https://www.example.com?" rel="canonical">1</a></li>
        <li><span>&hellip;</span></li>
        <li><a href="https://www.example.com?page=6" rel="prev">6</a></li>
        <li><a>7</a></li>
        <li><a href="https://www.example.com?page=8" rel="next">8</a></li>
        <li><span>&hellip;</span></li>
        <li><a href="https://www.example.com?page=15" rel="canonical">15</a></li>
        <li><a href="https://www.example.com?page=8" rel="next">NEXT</a></li>
      </ul>
    """

    assert rendered == compress_html(expected)
  end
end

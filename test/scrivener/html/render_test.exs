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
    {"<<", 6},
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
    {11, 11},
    {12, 12},
    {:ellipsis, {:safe, "&hellip;"}},
    {15, 15},
    {">>", 8}
  ]

  test "render without :html_attrs option" do
    rendered =
      render(@parsed, @page, path: "https://www.example.com") |> Phoenix.HTML.safe_to_string()

    expected = """
      <ul>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=6" rel="prev">&lt;&lt;</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?" rel="canonical">1</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=2" rel="canonical">2</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=3" rel="canonical">3</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=4" rel="canonical">4</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=5" rel="canonical">5</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=6" rel="prev">6</a></li>
         <li class="page-item"><a class="page-link">7</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=8" rel="next">8</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=9" rel="canonical">9</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=10" rel="canonical">10</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=11" rel="canonical">11</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=12" rel="canonical">12</a></li>
         <li class="page-item"><span>&hellip;</span></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=15" rel="canonical">15</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=8" rel="next">&gt;&gt;</a></li>
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
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=6" rel="prev">&lt;&lt;</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?" rel="canonical">1</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=2" rel="canonical">2</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=3" rel="canonical">3</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=4" rel="canonical">4</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=5" rel="canonical">5</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=6" rel="prev">6</a></li>
         <li class="page-item"><a class="page-link">7</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=8" rel="next">8</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=9" rel="canonical">9</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=10" rel="canonical">10</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=11" rel="canonical">11</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=12" rel="canonical">12</a></li>
         <li class="page-item"><span>&hellip;</span></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=15" rel="canonical">15</a></li>
         <li class="page-item"><a class="page-link" href="https://www.example.com?page=8" rel="next">&gt;&gt;</a></li>
      </ul>
    """

    assert rendered == compress_html(expected)
  end
end

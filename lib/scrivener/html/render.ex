defmodule Scrivener.HTML.Render do
  import Phoenix.HTML, only: [raw: 1]
  import Scrivener.HTML.Helper, only: [fetch_options: 2]
  alias Scrivener.Page

  @defaults [
    render_module: Scrivener.HTML.Render.Preset,
    html_attrs: [],
    hide_single: false,
    path: "",
    page_param: :page
  ]

  @moduledoc """
  Render raw data returned by `Scrivener.HTML.Parse.parse/2` to HTML.
  """
  def render(parsed, %Page{} = page, options) do
    options = fetch_options(options, @defaults)

    hide_single? = options[:hide_single] && page.total_pages < 2

    if hide_single? do
      raw(nil)
    else
      render_module = options[:render_module]
      html_attrs = options[:html_attrs]
      path = options[:path]
      page_param = options[:page_param]
      url_params = Keyword.drop(options, Keyword.keys(@defaults))

      items =
        Enum.map(parsed, fn item ->
          apply(render_module, :render_item, [
            item,
            page,
            path,
            page_param,
            url_params
          ])
        end)

      apply(render_module, :render_container, [html_attrs, [do: items]])
    end
  end

  @doc """
  Return default options.
  """
  def defaults(), do: @defaults
end

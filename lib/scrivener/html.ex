defmodule Scrivener.HTML do
  use Phoenix.HTML

  alias Scrivener.Page
  alias Scrivener.HTML.Parse
  alias Scrivener.HTML.Render

  @parse_defaults Parse.defaults()
  @render_defaults Render.defaults()

  @moduledoc """
  ## Usage

  Import `Scrivener.HTML` to your view:

      defmodule SampleWeb.UserView do
        use SampleWeb, :view
        use Scrivener.HTML
      end

  Use helper functions in your template:

      <%= pagination @page %>

  Where `@page` is a `%Scrivener.Page{}` struct.

  Read `Scrivener.HTML.pagination` for more details.

  ## SEO

  See `Scrivener.HTML.SEO` for more details.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import Scrivener.HTML
      import Scrivener.HTML.SEO
    end
  end

  @doc """
  Generates the HTML pagination for a given `%Scrivener.Page{}` returned by Scrivener.

  ## Available options

  Available `options` consists of options provided by `Scrivener.HTML.Parse` and
  `Scrivener.HTML.Render`.

  Default options of `Scrivener.HTML.Parse`:

  ```
  #{inspect(@parse_defaults, pretty: true, limit: :infinity)}
  ```

  Default options of `Scrivener.HTML.Render`:

  ```
  #{inspect(@render_defaults, pretty: true, limit: :infinity)}
  ```

  All other options will be considered as extra params of links.

  ## Examples

  Call `pagination/2` with `Scrivener.HTML.Parse` options:

      iex> pagination(%Scrivener.Page{total_pages: 10, page_number: 5}, distance: 4)

  Call `pagination/2` with more options:

      iex> pagination(%Scrivener.Page{total_pages: 10, page_number: 5}, page_param: :p, distance: 4)

  Call `pagination/2` with extra options:

      iex> pagination(%Scrivener.Page{total_pages: 10, page_number: 5}, my_param: "foobar")

  ## Custom HTML output

  ### Custom HTML attrs of container

      iex> pagination(%Scrivener.Page{total_pages: 10, page_number: 5}, html_attrs: [class: "pagination"])

  ### Custom previous and next buttons

      iex> pagination(%Scrivener.Page{total_pages: 10, page_number: 5}, previous: Phoenix.HTML.raw("&leftarrow;"), next: Phoenix.HTML.raw("&rightarrow;")

  ### Advanced customization

  Create a render module referencing `Scrivener.HTML.Render.Preset`, then use it
  by setting `:render_module` option.

  """
  def pagination(%Page{} = page, options \\ []) do
    parse_options = Keyword.take(options, Keyword.keys(@parse_defaults))
    render_options = Keyword.drop(options, Keyword.keys(@parse_defaults))

    page
    |> Parse.parse(parse_options)
    |> Render.render(page, render_options)
  end

  def defaults(), do: @parse_defaults ++ @render_defaults
end

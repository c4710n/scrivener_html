defmodule Scrivener.HTML do
  use Phoenix.HTML

  @defaults [
    render_module: Scrivener.HTML.Render,
    action: :index,
    page_param: :page,
    hide_single: false
  ]

  @raw_defaults [
    distance: 5,
    previous: "<<",
    next: ">>",
    first: true,
    last: true
  ]

  @moduledoc """
  ## Usage

  Import `Scrivener.HTML` to your view:

      defmodule SampleWeb.UserView do
        use SampleWeb, :view
        use Scrivener.HTML
      end

  Use helper functions in your template:

      <%= pagination_links @conn, @page %>

  Where `@page` is a `%Scrivener.Page{}` struct.

  ## Default values

  Below are the defaults.

      <%= pagination_links @conn, @page, distance: 5, next: ">>", previous: "<<", first: true, last: true %>

  For use with Phoenix.HTML, configure the `:routes_helper` option:

      config :scrivener_html,
        routes_helper: MyApp.Router.Helpers


  ## Custom HTML output

  See `Scrivener.HTML.raw_pagination_links/2` for more details.

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

  defmodule Default do
    @doc """
    Default path function when none provided. Used when automatic path function
    resolution cannot be performed.

        iex> Scrivener.HTML.Default.path(%Plug.Conn{}, :index, page: 4)
        "?page=4"
    """
    def path(_conn, _action, opts \\ []) do
      "?" <> Plug.Conn.Query.encode(opts)
    end
  end

  @doc """
  Generates the HTML pagination links for a given paginator returned by Scrivener.

  The default options are:

  ```
  #{inspect(@defaults ++ @raw_defaults, pretty: true)}
  ```

  An example of the output data:

      iex> Scrivener.HTML.pagination_links(%Scrivener.Page{total_pages: 10, page_number: 5}) |> Phoenix.HTML.safe_to_string()

  In order to generate links with nested objects (such as a list of comments for a given post)
  it is necessary to pass those arguments. All arguments in the `args` parameter will be directly
  passed to the path helper function. Everything within `opts` which are not options will passed
  as `params` to the path helper function. For example, `@post`, which has an index of paginated
  `@comments` would look like the following:

      Scrivener.HTML.pagination_links(@conn, @comments, [@post], my_param: "foo")

  You'll need to be sure to configure `:scrivener_html` with the `:routes_helper`
  module (ex. MyApp.Routes.Helpers) in Phoenix. With that configured, the above would generate calls
  to the `post_comment_path(@conn, :index, @post.id, my_param: "foo", page: page)` for each page link.

  In times that it is necessary to override the automatic path function resolution, you may supply the
  correct path function to use by adding an extra key in the `opts` parameter of `:path`.
  For example:

      Scrivener.HTML.pagination_links(@conn, @comments, [@post], path: &post_comment_path/4)

  Be sure to supply the function which accepts query string parameters (starts at arity 3, +1 for each relation),
  because the `page` parameter will always be supplied. If you supply the wrong function you will receive a
  function undefined exception.
  """
  def pagination_links(conn, paginator, args, opts) do
    opts =
      opts
      |> Keyword.merge(
        hide_single:
          opts[:hide_single] || Application.get_env(:scrivener_html, :hide_single, false)
      )

    merged_opts = Keyword.merge(@defaults, opts)

    path = opts[:path] || find_path_fn(conn && paginator.entries, args)
    params = Keyword.drop(opts, Keyword.keys(@defaults) ++ [:path, :hide_single])

    hide_single_result = opts[:hide_single] && paginator.total_pages < 2

    if hide_single_result do
      Phoenix.HTML.raw(nil)
    else
      # Ensure ordering so pattern matching is reliable
      _pagination_links(paginator,
        path: path,
        args: [conn, merged_opts[:action]] ++ args,
        page_param: merged_opts[:page_param],
        params: params
      )
    end
  end

  def pagination_links(%Scrivener.Page{} = paginator),
    do: pagination_links(nil, paginator, [], [])

  def pagination_links(%Scrivener.Page{} = paginator, opts),
    do: pagination_links(nil, paginator, [], opts)

  def pagination_links(conn, %Scrivener.Page{} = paginator),
    do: pagination_links(conn, paginator, [], [])

  def pagination_links(conn, paginator, [{_, _} | _] = opts),
    do: pagination_links(conn, paginator, [], opts)

  def pagination_links(conn, paginator, [_ | _] = args),
    do: pagination_links(conn, paginator, args, [])

  def find_path_fn(nil, _path_args), do: &Default.path/3
  def find_path_fn([], _path_args), do: fn _, _, _ -> nil end
  # Define a different version of `find_path_fn` whenever Phoenix is available.
  if Code.ensure_loaded(Phoenix.Naming) do
    def find_path_fn(entries, path_args) do
      routes_helper_module =
        Application.get_env(:scrivener_html, :routes_helper) ||
          raise(
            "Scrivener.HTML: Unable to find configured routes_helper module (ex. MyApp.Router.Helper)"
          )

      path = path_args |> Enum.reduce(name_for(List.first(entries), ""), &name_for/2)

      {path_fn, []} =
        Code.eval_quoted(
          quote do:
                  &(unquote(routes_helper_module).unquote(:"#{path <> "_path"}") /
                      unquote(length(path_args) + 3))
        )

      path_fn
    end
  else
    def find_path_fn(_entries, _args), do: &(Default / 3)
  end

  defp name_for(model, acc) do
    "#{acc}#{if(acc != "", do: "_")}#{Phoenix.Naming.resource_name(model.__struct__)}"
  end

  defp _pagination_links(paginator,
         path: path,
         args: args,
         page_param: page_param,
         params: params
       ) do
    url_params = Keyword.drop(params, Keyword.keys(@raw_defaults))

    Scrivener.HTML.Render.render_container do
      raw_pagination_links(paginator, params)
      |> Enum.map(
        &Scrivener.HTML.Render.render_item(&1, url_params, args, page_param, path, paginator)
      )
    end
  end

  @doc """
  Returns the raw data in order to generate the proper HTML for pagination links.

  ## Default options
  Default options are supplied as following:

  ```
  #{inspect(@raw_defaults)}
  ```

  + `distance` declares how many pages are shown. It is a positive integer.
  + `previous` and `next` declares text for previous and next buttons. Generally,
  they are string. Falsy values will remove them from output.
  + `first` and `last` declares whether show first or last page. Genrally, they are
  boolean values, but they can be strings.

  ## Return value
  Return value is a list of tuples. The tuple is in a `{text, page_number}` format
  where `text` is intended to be the text of the link and `page_number` is the
  page number it should go to.

  ## Examples

      iex(31)> Scrivener.HTML.raw_pagination_links(%{total_pages: 10, page_number: 5})
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

      iex> Scrivener.HTML.raw_pagination_links(%{total_pages: 15, page_number: 8}, first: "←", last: "→")
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

  Simply loop and pattern match over each item and transform them to your custom HTML.
  """
  def raw_pagination_links(paginator, options \\ []) do
    %{page_number: page_number, total_pages: total_pages} = paginator

    options = Keyword.merge(@raw_defaults, options)
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
  defp page_number_list(list, page, total, distance)
       when is_integer(distance) and distance >= 1 do
    list ++
      Enum.to_list(beginning_distance(page, total, distance)..end_distance(page, total, distance))
  end

  defp page_number_list(_list, _page, _total, _distance) do
    raise "Scrivener.HTML: Distance cannot be less than one."
  end

  # Beginning distance computation
  # For low page numbers
  defp beginning_distance(page, _total, distance) when page - distance < 1 do
    page - (distance + (page - distance - 1))
  end

  # For medium to high end page numbers
  defp beginning_distance(page, total, distance) when page <= total do
    page - distance
  end

  # For page numbers over the total number of pages (prevent DOS attack generating too many pages)
  defp beginning_distance(page, total, distance) when page > total do
    total - distance
  end

  # End distance computation
  # For high end page numbers (prevent DOS attack generating too many pages)
  defp end_distance(page, total, distance) when page + distance >= total and total != 0 do
    total
  end

  # For when there is no pages, cannot trust page number because it is supplied by user potentially (prevent DOS attack)
  defp end_distance(_page, 0, _distance) do
    1
  end

  # For low to mid range page numbers (guard here to ensure crash if something goes wrong)
  defp end_distance(page, total, distance) when page + distance < total do
    page + distance
  end

  # Adding next/prev/first/last links
  defp add_previous(list, page) when page != 1 do
    [:previous | list]
  end

  defp add_previous(list, _page) do
    list
  end

  defp add_first(list, page, distance, true) when page - distance > 1 do
    [1 | list]
  end

  defp add_first(list, page, distance, first) when page - distance > 1 and first != false do
    [:first | list]
  end

  defp add_first(list, _page, _distance, _included) do
    list
  end

  defp add_last(list, page, total, distance, true) when page + distance < total do
    list ++ [total]
  end

  defp add_last(list, page, total, distance, last)
       when page + distance < total and last != false do
    list ++ [:last]
  end

  defp add_last(list, _page, _total, _distance, _included) do
    list
  end

  defp add_next(list, page, total) when page != total and page < total do
    list ++ [:next]
  end

  defp add_next(list, _page, _total) do
    list
  end

  defp add_first_ellipsis(list, page, total, distance, true) do
    add_first_ellipsis(list, page, total, distance + 1, nil)
  end

  defp add_first_ellipsis(list, page, _total, distance, _first)
       when page - distance > 1 and page > 1 do
    list ++ [:first_ellipsis]
  end

  defp add_first_ellipsis(list, _page_number, _total, _distance, _first) do
    list
  end

  defp add_last_ellipsis(list, page, total, distance, true) do
    add_last_ellipsis(list, page, total, distance + 1, nil)
  end

  defp add_last_ellipsis(list, page, total, distance, _)
       when page + distance < total and page != total do
    list ++ [:last_ellipsis]
  end

  defp add_last_ellipsis(list, _page_number, _total, _distance, _last) do
    list
  end

  def defaults(), do: @defaults
end

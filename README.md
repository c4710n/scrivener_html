# Scrivener.HTML [![Build Status](https://semaphoreci.com/api/v1/projects/3b1ad27c-8991-4208-94d0-0bae42108482/638637/badge.svg)](https://semaphoreci.com/mgwidmann/scrivener_html)

Helpers built to work with [Scrivener](https://github.com/drewolson/scrivener)'s page struct to easily build HTML output for various CSS frameworks.

## Installation

Add `scrivener_html` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:scrivener_html, "~> 1.8"}
  ]
end
```

## Docs

Visit [HexDocs](https://hexdocs.pm/scrivener_html).

## Example Usage

### Scopes and URL Parameters

If your resource has any url parameters to be supplied, you should provide them as the 3rd parameter. For example, given a scope like:

```elixir
scope "/:locale", App do
  pipe_through [:browser]

  get "/page", PageController, :index, as: :pages
  get "/pages/:id", PageController, :show, as: :page
end
```

You would need to pass in the `:locale` parameter and `:path` option like so:

_(this would generate links like "/en/page?page=1")_

```elixir
<%= pagination_links @conn, @page, ["en"], path: &pages_path/4 %>
```

With a nested resource, simply add it to the list:

_(this would generate links like "/en/pages/1?page=1")_

```elixir
<%= pagination_links @conn, @page, ["en", @page_id], path: &page_path/4, action: :show %>
```

### Query String Parameters

Any additional query string parameters can be passed in as well.

```elixir
<%= pagination_links @conn, @page, ["en"], some_parameter: "data" %>
# Or if there are no URL parameters
<%= pagination_links @conn, @page, some_parameter: "data" %>
```

### Custom Actions

If you need to hit a different action other than `:index`, simply pass the action name to use in the url helper.

```elixir
<%= pagination_links @conn, @page, action: :show %>
```

### Customizing Output

Below are the defaults which are used without passing in any options.

```elixir
<%= pagination_links @conn, @page, [], distance: 5, next: ">>", previous: "<<", first: true, last: true, view_style: :bootstrap %>
# Which is the same as
<%= pagination_links @conn, @page %>
```

To prevent HTML escaping (i.e. seeing things like `&lt;` on the page), simply use `Phoenix.HTML.raw/1` for any `&amp;` strings passed in, like so:

```elixir
<%= pagination_links @conn, @page, previous: Phoenix.HTML.raw("&leftarrow;"), next: Phoenix.HTML.raw("&rightarrow;") %>
```

To show icons instead of text, simply render custom html templates, like:

_(this example uses materialize icons)_

```elixir
# Using Phoenix.HTML's sigil_E for EEx
<%= pagination_links @conn, @page, previous: ~E(<i class="material-icons">chevron_left</i>), next: ~E(<i class="material-icons">chevron_right</i>) %>
# Or by calling render
<%= pagination_links @conn, @page, previous: render("pagination.html", direction: :prev), next: render("pagination.html", direction: :next)) %>
```

The same can be done for first/last links as well (`v1.7.0` or higher).

_(this example uses materialize icons)_

```elixir
<%= pagination_links @conn, @page, first: ~E(<i class="material-icons">chevron_left</i>), last: ~E(<i class="material-icons">chevron_right</i>) %>
```

## License

MIT

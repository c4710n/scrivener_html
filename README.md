# scrivener_html_semi

> HTML helpers for Scrivener.

## Installation

Add `scrivener_html_semi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:scrivener_html_semi, "~> 1.8"}
  ]
end
```

## Docs

Visit [HexDocs](https://hexdocs.pm/scrivener_html_semi).

> Visit `Scrivener.HTML` for a quick start.

## Differences from scrivener_html

Unlike [scrivener_html](https://github.com/mgwidmann/scrivener_html), **scrivener_html_semi** doesn't provide any support of popular CSS frameworks. But, it provides full control of HTML output.

## Should I use this package?

If you are using existing CSS frameworks, such as Bootstrap or Bulma, you should use [scrivener_html](https://github.com/mgwidmann/scrivener_html).

If you want to customize HTML output manually, this package is for you.

## What is the meaning of the package name?

> `semi` is a meaningless suffix.

As you know, there's a package called scrivener_html. In order to distinguish between these two packages, I name this package as **scrivener_html_semi**.

## Why creating a new package rather than a PR?

There are lots of breaking changes, it's hard to creating a PR.

## License

MIT

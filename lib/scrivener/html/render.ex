defmodule Scrivener.HTML.Render do
  use Phoenix.HTML
  alias Scrivener.HTML.SEO

  @moduledoc """
  Return raw data returned by `Scrivener.HTML.raw_pagination_links/2` to HTML.
  """

  def render_container(do: block) do
    content_tag :nav do
      content_tag(:ul, [class: "pagination"], do: block)
    end
  end

  def render_item({:ellipsis, true}, url_params, args, page_param, path, paginator) do
    render_item(
      {:ellipsis, raw("&hellip;")},
      url_params,
      args,
      page_param,
      path,
      paginator
    )
  end

  def render_item({:ellipsis, text}, _url_params, _args, _page_param, _path, _paginator) do
    content_tag(:li, class: "page-item") do
      content_tag(:span, safe(text))
    end
  end

  def render_item({text, page_number}, url_params, args, page_param, path, paginator) do
    params_with_page =
      url_params ++
        case page_number > 1 do
          true -> [{page_param, page_number}]
          false -> []
        end

    content_tag :li, class: "page-item" do
      to = apply(path, args ++ [params_with_page])

      if to do
        if is_active_page?(paginator, page_number) do
          content_tag(:a, safe(text), class: "page-link")
        else
          link(safe(text),
            to: to,
            rel: SEO.rel(paginator, page_number),
            class: "page-link"
          )
        end
      else
        content_tag(:a, safe(text), class: "page-link")
      end
    end
  end

  defp is_active_page?(%{page_number: page_number}, page_number), do: true
  defp is_active_page?(_paginator, _page_number), do: false

  defp safe({:safe, _string} = whole_string) do
    whole_string
  end

  defp safe(string) when is_binary(string) do
    string
  end

  defp safe(string) do
    string
    |> to_string()
    |> raw()
  end
end

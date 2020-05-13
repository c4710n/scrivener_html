defmodule Scrivener.HTML.Render.Preset do
  use Phoenix.HTML
  alias Scrivener.HTML.SEO

  def render_container(do: block) do
    content_tag(:ul, block, class: "pagination")
  end

  def render_item({:ellipsis, true}, page, path, page_param, url_params) do
    render_item(
      {:ellipsis, raw("&hellip;")},
      page,
      path,
      page_param,
      url_params
    )
  end

  def render_item({:ellipsis, text}, _page, _path, _page_param, _url_params) do
    content_tag(:li, class: "page-item") do
      content_tag(:span, safe(text))
    end
  end

  def render_item({text, page_number}, page, path, page_param, url_params) do
    params =
      case page_number > 1 do
        true -> [{page_param, page_number}]
        false -> []
      end ++ url_params

    content_tag :li, class: "page-item" do
      query = URI.encode_query(params)
      to = "#{path}?#{query}"

      if to do
        if is_active_page?(page, page_number) do
          content_tag(:a, safe(text), class: "page-link")
        else
          link(safe(text),
            to: to,
            rel: SEO.rel(page, page_number),
            class: "page-link"
          )
        end
      else
        content_tag(:a, safe(text), class: "page-link")
      end
    end
  end

  defp is_active_page?(%{page_number: page_number}, page_number), do: true
  defp is_active_page?(_page, _page_number), do: false

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

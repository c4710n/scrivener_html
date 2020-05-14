defmodule Scrivener.HTML.Render.Preset do
  use Phoenix.HTML
  alias Scrivener.HTML.SEO

  def render_container(do: block) do
    content_tag(:ul, block, [])
  end

  def render_container(attrs, do: block) when is_list(attrs) do
    content_tag(:ul, block, attrs)
  end

  def render_item({:ellipsis, text}, _page, _path, _page_param, _url_params) do
    content_tag(:li) do
      content_tag(:span, safe(text))
    end
  end

  def render_item({atom, page_number, text}, page, path, page_param, url_params) do
    class = Atom.to_string(atom)
    to = get_url(path, page_param, page_number, url_params)
    rel = SEO.rel(page, page_number)

    content_tag :li do
      link(safe(text), to: to, rel: rel, class: class)
    end
  end

  # active page
  def render_item(
        {text, current_page_number},
        %{page_number: page_number},
        _path,
        _page_param,
        _url_params
      )
      when current_page_number == page_number do
    content_tag(:li) do
      content_tag(:a, safe(text))
    end
  end

  # other pages
  def render_item({text, page_number}, page, path, page_param, url_params) do
    to = get_url(path, page_param, page_number, url_params)
    rel = SEO.rel(page, page_number)

    content_tag :li do
      link(safe(text), to: to, rel: rel)
    end
  end

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

  defp get_url(path, page_param, page_number, url_params) do
    params = [{page_param, page_number}] ++ url_params
    query = URI.encode_query(params)
    "#{path}?#{query}"
  end
end

defmodule Scrivener.HTML.Helper do
  defp fetch_option(options, defaults, field) do
    value =
      options[field] ||
        Application.get_env(:scrivener_html, field) ||
        defaults[field]

    {field, value}
  end

  def fetch_options(options, defaults) do
    defaults
    |> Keyword.keys()
    |> Enum.map(&fetch_option(options, defaults, &1))
  end
end

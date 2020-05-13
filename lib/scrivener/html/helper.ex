defmodule Scrivener.HTML.Helper do
  defp fetch_option(options, defaults, field) do
    value_arg = options[field]
    value_config = Application.get_env(:scrivener_html, field)
    value_default = defaults[field]

    value =
      cond do
        !is_nil(value_arg) ->
          value_arg

        !is_nil(value_config) ->
          value_config

        true ->
          value_default
      end

    {field, value}
  end

  def fetch_options(options, defaults) do
    defaults
    |> Keyword.keys()
    |> Enum.map(&fetch_option(options, defaults, &1))
  end
end

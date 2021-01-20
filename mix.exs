defmodule Scrivener.HTML.MixProject do
  use Mix.Project

  @version "3.1.1"
  @github_url "https://github.com/c4710n/scrivener_html_semi"

  def project do
    [
      app: :scrivener_html_semi,
      description: "HTML helpers for Scrivener.",
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      aliases: aliases(),

      # Docs
      source_url: @github_url,
      homepage_url: @github_url,
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:scrivener, "~> 1.2 or ~> 2.0"},
      {:phoenix_html, ">= 0.0.0"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{GitHub: @github_url}
    ]
  end

  defp aliases do
    [publish: ["hex.publish", "tag"], tag: &tag_release/1]
  end

  defp tag_release(_) do
    Mix.shell().info("Tagging release as #{@version}")
    System.cmd("git", ["tag", "#{@version}"])
    System.cmd("git", ["push", "--tags"])
  end
end

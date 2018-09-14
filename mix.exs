defmodule GuardianPaseto.MixProject do
  use Mix.Project

  def project do
    [
      app: :guardian_paseto,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:guardian, "~> 1.0", override: true},
      {:paseto, "~> 1.0.0"},
      {:credo, "~> 0.9.0-rc1", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 0.1", only: :test},
      {:elixir_uuid, "~> 1.2"}
    ]
  end
end

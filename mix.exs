defmodule DrawOMatic.MixProject do
  use Mix.Project

  def project do
    [
      app: :draw_o_matic,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {DrawOMatic, []},
      extra_applications: [:crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.10.3", override: true},
      {:scenic_layout_o_matic, path: "~/workspace/scenic_layout_o_matic"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host}
    ]
  end
end

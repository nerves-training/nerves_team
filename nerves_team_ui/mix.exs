defmodule NervesTeamUI.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_team_ui,
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
      mod: {NervesTeamUI, []},
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.10"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:scenic_font_press_start_2p,
        github: "nerves-training/scenic_font_press_start_2p"},
      {:phoenix_client, "~> 0.6"},
      {:websocket_client, "~> 1.3"},
      {:jason, "~> 1.0"}
    ]
  end
end

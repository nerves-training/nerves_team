defmodule NervesTeamUI do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:nerves_team_ui, :viewport)

    socket_opts = Application.get_env(:nerves_team_ui, :socket)

    # start the application with the viewport
    children = [
      {Scenic, viewports: [main_viewport_config]},
      {PhoenixClient.Socket, {socket_opts, name: NervesTeamUI.Socket}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

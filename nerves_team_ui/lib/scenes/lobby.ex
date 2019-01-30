defmodule NervesTeamUI.Scene.Lobby do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  alias PhoenixClient.{Channel, Message}

  import Scenic.Primitives
  # import Scenic.Components

  require Logger

  @note """
  Lobby
  """

  @text_size 8

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    ScenicFontPressStart2p.load()
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    center = {0.5 * width, 0.5 * height}

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: @text_size)
      |> add_specs_to_graph([
        text_spec(@note, id: :title, text_align: :center, translate: center),
      ])

    {:ok, _reply, channel} = Channel.join(NervesTeamUI.Socket, "game:lobby")

    {:ok, %{
      graph: graph,
      viewport: opts[:viewport],
      channel: channel,
    }, push: graph}
  end

  def handle_info(:connect, %{viewport: viewport} = state) do
    if PhoenixClient.Socket.connected?(PhoenixClient.Socket) do
      ViewPort.set_root(viewport,
        {NervesTeamUI.Scene.Lobby, nil})
    else
      Process.send_after(self(), :connect, 1_000)
    end
    {:noreply, state}
  end

  def handle_info(%Message{event: event}, state)
    when event in ["phx_error", "phx_close"] do

    ViewPort.set_root(state.viewport,
      {NervesTeamUI.Scene.Home, nil})

    {:noreply, state}
  end

  def handle_info(
    %Message{event: "player:list", payload: %{"players" =>
      players}}, state) do

    player_ids =
      Enum.map(players, &Map.get(&1, "id")) |> Enum.join(",")
    state = update(:title, player_ids, state)
    {:noreply, state, push: state.graph}
  end

  def handle_info(message, state) do
    Logger.debug("Unhandled message: #{inspect(message)}")
    {:noreply, state}
  end

  defp update(element, text, state) do
    ScenicFontPressStart2p.load()
    graph =
      state.graph
      |> Graph.modify(element, &text(&1, text))

    %{state | graph: graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, state}
  end
end

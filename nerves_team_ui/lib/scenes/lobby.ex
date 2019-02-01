defmodule NervesTeamUI.Scene.Lobby do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  alias PhoenixClient.{Channel, Message}

  import Scenic.Primitives
  # import Scenic.Components

  alias NervesTeamUI.Component.Device, as: DeviceComponent
  alias NervesTeamUI.Component.Progress, as: ProgressComponent

  require Logger

  @ready_key " "
  @col 5

  @text_size 8

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    viewport = opts[:viewport]

    ScenicFontPressStart2p.load()

    {:ok, %ViewPort.Status{size: {_, vp_height}}} = ViewPort.info(viewport)

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: @text_size)
      |> ProgressComponent.add_to_graph([value: 0], id: :progress)
      |> text("Waiting\nfor\nplayers",
        id: :waiting,
        text_align: :left,
        translate: {38, (vp_height - 6) / 2 + 6}
      )
      |> DeviceComponent.add_to_graph([server_id: nil],
        id: :me,
        translate: {0, 5},
        width: 34,
        height: 57,
        font_size: 18
      )

    {:ok, _, channel} = Channel.join(NervesTeamUI.Socket, "game:lobby")

    {:ok,
     %{
       viewport: viewport,
       graph: graph,
       channel: channel,
       players: [],
       id: nil
     }, push: graph}
  end

  def handle_info(%Message{event: event}, %{viewport: vp} = s)
      when event in ["phx_error", "phx_close"] do
    ViewPort.set_root(vp, {NervesTeamUI.Scene.Connect, nil})
    {:noreply, s}
  end

  def handle_info(
        %Message{event: "player:list", payload: %{"players" => players}},
        %{graph: graph} = s
      ) do
    ScenicFontPressStart2p.load()
    players = Enum.reject(players, &(&1["id"] == s.id))
    graph = render_devices(players, graph)
    {:noreply, %{s | graph: graph, players: players}, push: graph}
  end

  def handle_info(%Message{event: "player:assigned", payload: %{"id" => id}}, %{graph: graph} = s) do
    ScenicFontPressStart2p.load()

    graph =
      graph
      |> Graph.modify(:me, fn %{data: {mod, data}} = p ->
        Scenic.Primitive.put(p, {mod, Keyword.put(data, :server_id, id)}, [])
      end)

    {:noreply, %{s | id: id, graph: graph}, push: graph}
  end

  def handle_info(
        %Message{event: "player:joined", payload: player},
        %{graph: graph, players: players} = s
      ) do
    ScenicFontPressStart2p.load()
    IO.puts("Player Joined: #{inspect(player)}")
    players = [player | players]
    graph = render_devices(players, graph)
    {:noreply, %{s | players: players, graph: graph}, push: graph}
  end

  def handle_info(
        %Message{event: "player:left", payload: %{"id" => id}},
        %{graph: graph, players: players} = s
      ) do
    ScenicFontPressStart2p.load()
    IO.puts("Player Left: #{inspect(id)}")
    players = Enum.reject(players, &(&1["id"] == id))
    graph = delete_device_component(id, graph)
    graph = render_devices(players, graph)
    {:noreply, %{s | players: players, graph: graph}, push: graph}
  end

  def handle_info(
        %Message{event: "player:ready", payload: %{"id" => id, "ready" => ready?}},
        %{graph: graph} = s
      ) do
    ScenicFontPressStart2p.load()
    id = if id == s.id, do: :me, else: :"device_#{id}"

    graph =
      graph
      |> Graph.modify(id, fn %{data: {mod, data}} = p ->
        Scenic.Primitive.put(p, {mod, Keyword.put(data, :ready, ready?)}, [])
      end)

    {:noreply, %{s | graph: graph}, push: graph}
  end

  def handle_info(%Message{event: "game:wait"}, %{graph: graph} = s) do
    ScenicFontPressStart2p.load()
    Logger.debug("Game: Waiting for more players")

    graph =
      graph
      |> Graph.modify(:progress, fn %{data: {mod, data}} = p ->
        data =
          data
          |> Keyword.put(:duration, false)
          |> Keyword.put(:value, 0)

        Scenic.Primitive.put(p, {mod, data}, [])
      end)

    {:noreply, %{s | graph: graph}, push: graph}
  end

  def handle_info(
        %Message{event: "game:pending", payload: %{"duration" => duration}},
        %{graph: graph} = s
      ) do
    ScenicFontPressStart2p.load()
    Logger.debug("Game: About to start")

    graph =
      graph
      |> Graph.modify(:progress, fn %{data: {mod, data}} = p ->
        Scenic.Primitive.put(p, {mod, Keyword.put(data, :duration, duration)}, [])
      end)

    {:noreply, %{s | graph: graph}, push: graph}
  end

  def handle_info(
        %Message{event: "game:start", payload: %{"game_id" => game_id}},
        %{viewport: vp} = s
      ) do
    Logger.debug("Game: Starting")
    ViewPort.set_root(vp, {NervesTeamUI.Scene.Game, %{game_id: game_id, player_id: s.id}})
    {:noreply, s}
  end

  def handle_info(message, s) do
    Logger.debug("Lobby: #{inspect(message)}")
    {:noreply, s}
  end

  def handle_input({:key, {@ready_key, :press, _}}, _context, s) do
    Channel.push(s.channel, "player:ready", %{ready: true})
    {:noreply, s}
  end

  def handle_input({:key, {@ready_key, :release, _}}, _context, s) do
    Channel.push(s.channel, "player:ready", %{ready: false})
    {:noreply, s}
  end

  def handle_input(_, _context, s) do
    {:noreply, s}
  end

  def add_device_component(id, graph, position) do
    graph
    |> DeviceComponent.add_to_graph([server_id: id],
      id: :"device_#{id}",
      translate: position,
      font_size: 6
    )
  end

  def delete_device_component(id, graph) do
    graph
    |> Graph.delete(:"device_#{id}")
  end

  def render_devices([], graph) do
    graph
    |> Graph.modify(:waiting, &update_opts(&1, hidden: false))
  end

  def render_devices(devices, graph) do
    graph = Graph.modify(graph, :waiting, &update_opts(&1, hidden: true))

    {_, graph} =
      Enum.reduce(devices, {0, graph}, fn %{"id" => id}, {idx, graph} ->
        row = div(idx, @col)
        col = rem(idx, @col)
        scenic_id = :"device_#{id}"
        position = {34 + 19 * col, 5 + 19 * row}

        graph =
          case Graph.get(graph, scenic_id) do
            [] ->
              add_device_component(id, graph, position)

            _ ->
              graph
              |> Graph.modify(scenic_id, &update_opts(&1, translate: position))
          end

        {idx + 1, graph}
      end)

    graph
  end
end

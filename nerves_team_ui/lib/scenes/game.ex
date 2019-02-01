defmodule NervesTeamUI.Scene.Game do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias ScenicFontPressStart2p
  alias NervesTeamUI.Component.Progress, as: ProgressComponent
  alias NervesTeamUI.Component.Action, as: ActionComponent
  alias PhoenixClient.{Channel, Message}

  import Scenic.Primitives

  require Logger

  @title "Waiting for\nplayers"

  @action_keys ["A", "S"]

  @text_size 8

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(%{game_id: game_id, player_id: player_id}, opts) do
    ScenicFontPressStart2p.load()
    viewport = opts[:viewport]
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: @text_size)
      |> ProgressComponent.add_to_graph([duration: false], value: 100, id: :task_progress)
      |> ProgressComponent.add_to_graph([value: 50],
        id: :game_progress,
        translate: {0, vp_height - 5}
      )
      |> text(@title,
        id: :status,
        text_align: :center,
        translate: {vp_width / 2, 18},
        hidden: false
      )
      |> text("", id: :task, text_align: :center, translate: {vp_width / 2, 18}, hidden: true)
      |> rect({vp_width, 1}, fill: :white, translate: {0, vp_height / 2})
      |> rect({1, vp_height / 2 - 5}, fill: :white, translate: {vp_width / 2, vp_height / 2})

    {:ok, _, channel} = Channel.join(NervesTeamUI.Socket, "game:#{game_id}", %{player_id: player_id})

    {:ok,
     %{
       viewport: viewport,
       graph: graph,
       channel: channel,
       game_id: game_id,
       task: nil,
       action_0: nil,
       action_1: nil
     }, push: graph}
  end

  def handle_info(%Message{event: :close}, %{viewport: vp} = s) do
    ViewPort.set_root(vp, {NervesTeamUI.Scene.Connect, nil})
    {:noreply, s}
  end

  def handle_info(%Message{event: "game:ended", payload: %{"win?" => win?}}, %{viewport: vp} = s) do
    Logger.debug("Game: Ended")
    ViewPort.set_root(vp, {NervesTeamUI.Scene.GameOver, win?})
    {:noreply, s}
  end

  def handle_info(
        %Message{event: "actions:assigned", payload: payload},
        %{graph: graph, viewport: vp} = s
      ) do
    %{"actions" => [action_0, action_1] = actions} = payload
    ScenicFontPressStart2p.load()
    Logger.debug("Actions assigned: #{inspect(actions)}")
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(vp)

    graph =
      graph
      |> ActionComponent.add_to_graph([action: action_0],
        id: :action_0,
        translate: {0, vp_height / 2 + 1}
      )
      |> ActionComponent.add_to_graph([action: action_1],
        id: :action_1,
        translate: {vp_width / 2 + 1, vp_height / 2 + 1}
      )

    {:noreply, %{s | graph: graph, action_0: action_0, action_1: action_1}, push: graph}
  end

  def handle_info(%Message{event: "task:assigned", payload: task}, %{graph: graph} = s) do
    Logger.debug("Task assigned: #{inspect(task)}")
    ScenicFontPressStart2p.load()

    graph =
      graph
      |> Graph.modify(:task, &text(&1, task["title"]))
      |> Graph.modify(:task_progress, fn %{data: {mod, data}} = p ->
        Scenic.Primitive.put(p, {mod, Keyword.put(data, :duration, false)}, [])
      end)
      |> Graph.modify(:task_progress, fn %{data: {mod, data}} = p ->
        data =
          data
          |> Keyword.put(:duration, task["expire"])
          |> Keyword.put(:value, 100)

        Scenic.Primitive.put(p, {mod, data}, [])
      end)

    {:noreply, %{s | graph: graph, task: task}, push: graph}
  end

  def handle_info(%Message{event: "game:prepare"}, %{graph: graph} = s) do
    ScenicFontPressStart2p.load()

    graph =
      graph
      |> Graph.modify(:status, &text(&1, "Get ready!"))

    {:noreply, %{s | graph: graph}, push: graph}
  end

  def handle_info(%Message{event: "game:starting"}, %{graph: graph} = s) do
    ScenicFontPressStart2p.load()

    graph =
      graph
      |> Graph.modify(:status, &text(&1, "Go!"))

    {:noreply, %{s | graph: graph}, push: graph}
  end

  def handle_info(%Message{event: "game:start"}, %{graph: graph} = s) do
    ScenicFontPressStart2p.load()

    graph =
      graph
      |> Graph.modify(:status, &update_opts(&1, hidden: true))
      |> Graph.modify(:task, &update_opts(&1, hidden: false))
      |> Graph.modify(:task_progress, fn %{data: {mod, data}} = p ->
        Scenic.Primitive.put(p, {mod, Keyword.put(data, :duration, s.task["expire"])}, [])
      end)

    {:noreply, %{s | graph: graph}, push: graph}
  end

  def handle_info(
        %Message{event: "game:progress", payload: %{"percent" => percent}},
        %{graph: graph} = s
      ) do
    ScenicFontPressStart2p.load()

    graph =
      graph
      |> Graph.modify(:game_progress, fn %{data: {mod, data}} = p ->
        data =
          data
          |> Keyword.put(:percent, percent)

        Scenic.Primitive.put(p, {mod, data}, [])
      end)

    {:noreply, %{s | graph: graph}, push: graph}
  end

  def handle_info(message, s) do
    Logger.debug("Game: #{inspect(message)}")
    {:noreply, s}
  end

  def handle_input({:key, {key, action, _}}, _context, %{graph: graph} = s)
      when key in @action_keys do
    ScenicFontPressStart2p.load()
    idx = Enum.find_index(@action_keys, &(&1 == key))
    action_id = :"action_#{idx}"
    pressed? = action == :press

    graph =
      graph
      |> Graph.modify(action_id, fn %{data: {mod, data}} = p ->
        Scenic.Primitive.put(p, {mod, Keyword.put(data, :pressed?, pressed?)}, [])
      end)

    [%{data: {_mod, data}}] = Graph.get(graph, action_id)

    if pressed? do
      Channel.push(s.channel, "action:execute", data[:action])
    end

    {:noreply, %{s | graph: graph}, push: graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, state}
  end
end

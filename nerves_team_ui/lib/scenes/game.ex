defmodule NervesTeamUI.Scene.Game do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  alias PhoenixClient.{Socket, Channel, Message}

  import Scenic.Primitives
  # import Scenic.Components

  require Logger

  @note """
  Get ready!
  """
  @action_key ["A", "S"]

  @text_size 8

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(payload, opts) do
    ScenicFontPressStart2p.load()
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    top =   {0.5  * width, 0.25 * height}
    left =  {0.25 * width, 0.75 * height}
    right = {0.75 * width, 0.75 * height}

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: @text_size)
      |> add_specs_to_graph([
        text_spec(@note, id: :title, text_align: :center, translate: top),
        text_spec("", id: :action1, text_align: :center, translate: left),
        text_spec("", id: :action2, text_align: :center, translate: right),
      ])

    %{"game_id" => game_id} = payload

    {:ok, _reply, channel} = Channel.join(Socket, "game:" <> game_id, payload)

    {:ok, %{
      graph: graph,
      viewport: opts[:viewport],
      channel: channel,
      actions: []
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

  def handle_info(
    %Message{event: "task:assigned", payload: task}, state) do

    %{"title" => task_name} = task
    state = update(:title, task_name, state)
    {:noreply, state, push: state}
  end

  def handle_info(
    %Message{event: "actions:assigned", payload: payload},
      state) do

    %{"actions" =>  actions} = payload
    state = update(:action1, Enum.at(actions, 0)["title"], state)
    state = update(:action2, Enum.at(actions, 1)["title"], state)
    {:noreply, %{state | actions: actions}, push: state.graph}
  end

  def handle_info(
    %Message{event: "game:ended", payload: payload}, state) do

    :timer.apply_after(5_000, ViewPort, :set_root,
      [state.viewport, {NervesTeamUI.Scene.Home, nil}])
    text = if payload["win?"], do: "You win", else: "You lose"
    state = update(:title, text, state)
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

  def handle_input({:key, {key, action, _}}, _context, state)
    when action in [:press, :release]
    and key in @action_key do

    index = Enum.find_index(@action_key, & &1 == key)
    action = Enum.at(state.actions, index)
    Channel.push(state.channel, "action:execute", action)
    {:noreply, state}
  end

  def handle_input({:key, {@action_key, action, _}}, _context, state)
    when action in [:press, :release] do

    ready? = action == :press
    Channel.push(state.channel, "player:ready",%{ready: ready?})
    {:noreply, state}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, state}
  end
end

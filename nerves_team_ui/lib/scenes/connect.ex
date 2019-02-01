defmodule NervesTeamUI.Scene.Connect do
  use Scenic.Scene

  alias Scenic.{Graph, ViewPort}

  import Scenic.Primitives

  @delay 1000

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    ScenicFontPressStart2p.load()

    viewport = opts[:viewport]

    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)
    position = {vp_width / 2, vp_height / 2}

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: 8)
      |> text("Connecting", id: :title, text_align: :center, translate: position)

    Process.send_after(self(), :update, @delay)

    {:ok,
     %{
       viewport: viewport,
       graph: graph
     }, push: graph}
  end

  def handle_info(:update, %{graph: graph} = s) do
    ScenicFontPressStart2p.load()

    if PhoenixClient.Socket.connected?(NervesTeamUI.Socket) do
      graph =
        graph
        |> Graph.modify(:title, &text(&1, "Connected!"))

      Process.send_after(self(), :finish, @delay)
      {:noreply, s, push: graph}
    else
      Process.send_after(self(), :update, 500)
      {:noreply, s}
    end
  end

  def handle_info(:finish, %{viewport: vp} = s) do
    ViewPort.set_root(vp, {NervesTeamUI.Scene.Lobby, nil})
    {:noreply, s}
  end
end

defmodule NervesTeamUI.Scene.GameOver do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias ScenicFontPressStart2p

  import Scenic.Primitives

  @title "GameOver"
  @win "You win!"
  @lose "You lose!"
  @delay 5000

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(win?, opts) do
    viewport = opts[:viewport]

    ScenicFontPressStart2p.load()

    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)
    center = {vp_width * 0.5, vp_height * 0.5}
    bottom = {vp_width * 0.5, vp_height * 0.75}
    win_lose = if win?, do: @win, else: @lose

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: 8)
      |> text(@title, id: :title, fill: :white, text_align: :center, translate: center)
      |> text(win_lose, id: :win_lose, fill: :white, text_align: :center, translate: bottom)

    Process.send_after(self(), :finish, @delay)

    {:ok,
     %{
       viewport: viewport,
       graph: graph
     }, push: graph}
  end

  def handle_info(:finish, %{viewport: vp} = s) do
    ViewPort.set_root(vp, {NervesTeamUI.Scene.Connect, nil})
    {:noreply, s}
  end
end

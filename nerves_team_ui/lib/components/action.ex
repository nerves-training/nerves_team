defmodule NervesTeamUI.Component.Action do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias ScenicFontPressStart2p

  import Scenic.Primitives, only: [rect: 3, text: 3, update_opts: 2]

  @width 63
  @height 23
  @font_size 8

  # --------------------------------------------------------
  def verify(data), do: {:ok, data}

  # ----------------------------------------------------------------------------
  def init(opts, config) do
    ScenicFontPressStart2p.load()
    styles = config[:styles]
    width = config[:styles][:width] || @width
    height = config[:styles][:height] || @height
    font_size = @font_size
    pressed? = opts[:pressed?] || false
    action = opts[:action]

    position = {width * 0.5, height * 0.5}

    graph =
      Graph.build(styles: styles)
      |> rect({width, height}, id: :box)
      |> text(action["title"],
        id: :title,
        text_align: :center,
        translate: position,
        font_size: font_size,
        font: ScenicFontPressStart2p.hash()
      )
      |> pressed?(pressed?)

    {:ok,
     %{
       graph: graph,
       viewport: config[:viewport],
       width: width,
       height: height,
       action: action
     }, push: graph}
  end

  def pressed?(graph, true) do
    graph
    |> Graph.modify(:box, &update_opts(&1, fill: :white))
    |> Graph.modify(:title, &update_opts(&1, fill: :black))
  end

  def pressed?(graph, false) do
    graph
    |> Graph.modify(:box, &update_opts(&1, fill: :black))
    |> Graph.modify(:title, &update_opts(&1, fill: :white))
  end
end

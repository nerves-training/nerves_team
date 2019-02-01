defmodule NervesTeamUI.Component.Device do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias ScenicFontPressStart2p

  import Scenic.Primitives, only: [rect: 3, text: 3, update_opts: 2]

  @width 20
  @height 20
  # --------------------------------------------------------
  def verify(data), do: {:ok, data}

  # ----------------------------------------------------------------------------
  def init(opts, config) do
    ScenicFontPressStart2p.load()
    styles = config[:styles]
    width = config[:styles][:width] || @width
    height = config[:styles][:height] || @height
    server_id = opts[:server_id] || "?"
    ready = opts[:ready] || false

    position = {width * 0.5, height * 0.5 + 2}

    graph =
      Graph.build(styles: styles)
      |> rect({width, height}, id: :box, stroke: {1, :white})
      |> text(server_id,
        id: :text,
        text_align: :center,
        translate: position,
        font_size: styles.font_size,
        font: ScenicFontPressStart2p.hash()
      )
      |> ready(ready)

    {:ok,
     %{
       graph: graph,
       viewport: opts[:viewport],
       width: width,
       height: height,
       id: config[:id]
     }, push: graph}
  end

  defp ready(graph, false) do
    graph
    |> Graph.modify(:box, &update_opts(&1, fill: :black))
    |> Graph.modify(:text, &update_opts(&1, fill: :white))
  end

  defp ready(graph, true) do
    graph
    |> Graph.modify(:box, &update_opts(&1, fill: :white))
    |> Graph.modify(:text, &update_opts(&1, fill: :black))
  end
end

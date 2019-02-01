defmodule NervesTeamUI.Component.Progress do
  use Scenic.Component

  alias Scenic.ViewPort
  alias Scenic.Graph

  import Scenic.Primitives, only: [rect: 3, rect: 2]

  @height 5

  # --------------------------------------------------------
  def verify(data), do: {:ok, data}

  # ----------------------------------------------------------------------------
  def init(opts, config) do
    styles = config[:styles] || %{}

    min = opts[:min] || 0
    max = opts[:max] || 100

    value =
      if percent = opts[:percent] do
        trunc(max * percent)
      else
        opts[:value] || 100
      end

    duration = opts[:duration] || false

    timer_ref =
      if duration do
        interval = trunc(duration / max)
        {:ok, {_, timer_ref}} = :timer.send_interval(interval, :tick)
        timer_ref
      end

    # Get the viewport width
    {:ok, %ViewPort.Status{size: {width, _}}} =
      config[:viewport]
      |> ViewPort.info()

    graph =
      Graph.build(styles: styles)
      |> rect({width, @height}, fill: :black, stroke: {2, :white})
      |> rect({trunc(width * (value / max)), @height}, id: :progress, fill: :white)

    direction = if value == max, do: :down, else: :up

    {:ok,
     %{
       graph: graph,
       viewport: config[:viewport],
       width: width,
       min: min,
       max: max,
       value: value,
       direction: direction,
       timer_ref: timer_ref
     }, push: graph}
  end

  def handle_info(
        :tick,
        %{direction: direction, graph: graph, value: value, max: max, min: min} = s
      )
      when value >= min and value <= max do
    value =
      case direction do
        :down -> value - 1
        :up -> value + 1
      end

    {:ok, %ViewPort.Status{size: {width, _}}} = ViewPort.info(s.viewport)

    graph =
      graph
      |> Graph.modify(:progress, &rect(&1, {trunc(width * (value / max)), @height}))

    {:noreply, %{s | graph: graph, value: value}, push: graph}
  end

  def handle_info(:tick, %{timer_ref: timer_ref} = s) do
    if timer_ref do
      Process.cancel_timer(timer_ref)
    end

    {:noreply, %{s | timer_ref: nil}}
  end
end

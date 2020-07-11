defmodule DrawOMatic.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

  @graph Graph.build(clear_color: :white)

  defmodule State do
    defstruct [:graph, :drawing, :viewport, :prev_coords]
  end

  @impl true
  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {width, height}} = viewport} = ViewPort.info(opts[:viewport])

    graph =
      @graph
      |> rect({width, height})
      |> button("Clear", t: {600, 0}, id: :clear_graph)

    state = %State{graph: graph, viewport: viewport}

    {:ok, state, push: graph}
  end

  @impl true
  def handle_input(input, context, state) do
    do_handle_input(input, context, state)
  end

  @impl true
  def filter_event({:click, :clear_graph}, _, state) do
    graph = Graph.delete(state.graph, :drawn_line)

    state = %State{drawing: false, graph: graph, prev_coords: nil}
    {:noreply, state, push: graph}
  end

  def do_handle_input(
        {:cursor_button, {:left, :press, _, cursor_coords}},
        _context,
        state
      ) do
    graph =
      state.graph
      |> line({cursor_coords, cursor_coords}, stroke: {2, :black}, id: :drawn_line)

    state = %State{state | drawing: true, graph: graph, prev_coords: cursor_coords}

    {:noreply, state, push: graph}
  end

  def do_handle_input(
        {:cursor_button, {:left, :release, _, _cursor_coords}},
        _context,
        state
      ) do
    state = %State{state | drawing: false}

    {:noreply, state}
  end

  def do_handle_input({:cursor_pos, cursor_coords}, _context, %{drawing: true} = state) do
    graph = Map.get(state, :graph)
    prev_coords = Map.get(state, :prev_coords)

    graph = graph |> line({prev_coords, cursor_coords}, stroke: {2, :black}, id: :drawn_line)

    state = %State{state | graph: graph, prev_coords: cursor_coords}

    {:noreply, state, push: graph}
  end

  def do_handle_input(_input, _context, state) do
    {:noreply, state}
  end
end

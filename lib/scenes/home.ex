defmodule DrawOMatic.Scene.Home do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

  defmodule State do
    defstruct [:graph, :drawing, :viewport, :prev_coords, :stroke, :super, :saved]
  end

  @impl true
  def init(_, opts) do
    state =
      case File.read("state.bin") do
        {:ok, state} ->
          :erlang.binary_to_term(state)

        {:error, _} ->
          graph = Graph.build(clear_color: :white)

          {:ok, %ViewPort.Status{size: {width, height}} = viewport} =
            ViewPort.info(opts[:viewport])

          graph =
            graph
            |> rect({width, height})
            |> button("Clear", t: {600, 0}, id: :clear_graph)

          %State{graph: graph, viewport: viewport, stroke: {2, :black}}
      end

    {:ok, state, push: state.graph}
  end

  @impl true
  def filter_event({:click, :clear_graph}, _, state) do
    graph = Graph.delete(state.graph, :drawn_line) |> IO.inspect()

    state = %State{drawing: false, graph: graph, prev_coords: nil}
    {:noreply, state, push: graph}
  end

  @impl true
  def handle_input(input, context, state) do
    do_handle_input(input, context, state)
  end

  def do_handle_input(
        {:cursor_button, {:left, :press, _, cursor_coords}},
        _context,
        state
      ) do
    graph =
      state.graph
      |> line({cursor_coords, cursor_coords},
        stroke: state.stroke,
        id: drawn_line_id(cursor_coords)
      )

    state = %State{state | drawing: true, graph: graph, prev_coords: cursor_coords}

    {:noreply, state, push: graph}
  end

  def do_handle_input({:key, {key, :press, _}}, _context, state)
      when key in ["left_super", "right_super"] do
    state = %{state | super: true}
    {:noreply, state}
  end

  def do_handle_input({:key, {key, :release, _}}, _context, state)
      when key in ["left_super", "right_super"] do
    state = %{state | super: false}
    {:noreply, state}
  end

  def do_handle_input({:key, {key, :press, _}}, _context, %{super: true} = state)
      when key in ["S"] do
    File.write!("state.bin", :erlang.term_to_binary(state))
    IO.inspect("We saved!")
    state = %{state | saved: true}
    {:noreply, state}
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

    graph =
      graph
      |> line({prev_coords, cursor_coords},
        stroke: {2, :black},
        id: drawn_line_id(cursor_coords)
      )

    state = %State{state | graph: graph, prev_coords: cursor_coords}

    {:noreply, state, push: graph}
  end

  def do_handle_input(_input, _context, state) do
    {:noreply, state}
  end

  defp drawn_line_id(_cursor_coords) do
    :drawn_line
    # :" <>
    #   Float.to_string(elem(cursor_coords, 0)) <>
    #   "," <> Float.to_string(elem(cursor_coords, 1))
  end
end

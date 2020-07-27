defmodule DrawOMatic.Scene.Home do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

  require Logger

  @group_name :drawn_group_id

  defmodule State do
    defstruct [
      :graph,
      :drawing,
      :viewport,
      :prev_coords,
      :stroke,
      :super,
      :saved,
      :erasing,
      :timer
    ]
  end

  @impl true
  def init(_, opts) do
    Process.flag(:trap_exit, true)

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
  # event for clicking 'Clear' button.
  def filter_event({:click, :clear_graph}, _, state) do
    graph = Graph.delete(state.graph, @group_name)

    state = %State{drawing: false, graph: graph, prev_coords: nil}
    {:noreply, state, push: graph}
  end

  # event for dismissing save toast
  def filter_event({:click, :save_toast}, _, state) do
    :timer.cancel(state.timer)
    graph = Graph.delete(state.graph, :save_toast)
    state = %State{state | graph: graph, timer: nil}
    {:noreply, state, push: graph}
  end

  # handle timer to dismiss toast
  @impl true
  def handle_info(:remove_save_toast, state) do
    :timer.cancel(state.timer)
    graph = Graph.delete(state.graph, :save_toast)
    state = %{state | graph: graph}
    {:noreply, state, push: graph}
  end

  @impl true
  def handle_input(input, context, state) do
    do_handle_input(input, context, state)
  end

  def do_handle_input(
        {:cursor_button, {:left, :press, _, cursor_coords}},
        _context,
        %{super: true} = state
      ) do
    graph = Graph.delete(state.graph, drawn_line_id(cursor_coords))
    state = %State{state | graph: graph, erasing: true, drawing: false}
    {:noreply, state, push: graph}
  end

  # Handles drawing initial line
  def do_handle_input(
        {:cursor_button, {:left, :press, _, cursor_coords}},
        _context,
        state
      ) do
    graph =
      case Graph.get(state.graph, @group_name) do
        [_ | _] ->
          add_line_to_group(state, cursor_coords, cursor_coords)

        _ ->
          group(
            state.graph,
            fn g ->
              line(g, {cursor_coords, cursor_coords},
                stroke: state.stroke,
                id: drawn_line_id(cursor_coords)
              )
            end,
            id: @group_name
          )
      end

    state = %State{
      state
      | drawing: true,
        graph: graph,
        prev_coords: cursor_coords,
        erasing: false
    }

    {:noreply, state, push: graph}
  end

  def do_handle_input(
        {:cursor_pos, cursor_coords},
        _context,
        %{erasing: true, super: true} = state
      ) do
    graph = Graph.delete(state.graph, drawn_line_id(cursor_coords))
    state = %State{state | graph: graph, erasing: true, drawing: false}
    {:noreply, state, push: graph}
  end

  def do_handle_input({:cursor_button, {:right, :press, _, cursor_coords}}, _context, state) do
    graph = Graph.delete(state.graph, drawn_line_id(cursor_coords))
    state = %State{state | graph: graph, erasing: true, drawing: false}
    {:noreply, state, push: graph}
  end

  def do_handle_input({:cursor_pos, cursor_coords}, _context, %{erasing: true} = state) do
    graph = Graph.delete(state.graph, drawn_line_id(cursor_coords))
    state = %State{state | graph: graph, drawing: false}
    {:noreply, state, push: graph}
  end

  def do_handle_input({:cursor_button, {:right, :release, _, _}}, _context, state) do
    state = %State{state | erasing: false}
    {:noreply, state}
  end

  # Handles super key input used for hot keys
  def do_handle_input({:key, {key, :press, _}}, _context, state)
      when key in ["left_super", "right_super"] do
    state = %State{state | super: true}
    {:noreply, state}
  end

  # Handles super key release
  def do_handle_input({:key, {key, :release, _}}, _context, state)
      when key in ["left_super", "right_super"] do
    state = %State{state | super: false}
    {:noreply, state}
  end

  # Handles 's' key input to save state
  def do_handle_input({:key, {"S", :press, _}}, _context, %{super: true} = state) do
    state =
      case save_state(state) do
        :ok ->
          graph = state.graph |> button("File Saved", theme: :success, id: :save_toast)
          timer = Process.send_after(self(), :remove_save_toast, 3_500)
          %State{state | graph: graph, saved: true, timer: timer}

        {:error, _} ->
          nil
      end

    {:noreply, state, push: state.graph}
  end

  # Stop drawing
  def do_handle_input(
        {:cursor_button, {:left, :release, _, _cursor_coords}},
        _context,
        state
      ) do
    state = %State{state | drawing: false, erasing: false}

    {:noreply, state}
  end

  # Handles drawing from previous point to current point
  def do_handle_input({:cursor_pos, cursor_coords}, _context, %{drawing: true} = state) do
    prev_coords = Map.get(state, :prev_coords)

    graph = add_line_to_group(state, prev_coords, cursor_coords)
    state = %State{state | graph: graph, prev_coords: cursor_coords, erasing: false}

    {:noreply, state, push: graph}
  end

  # Handles quitting app
  def do_handle_input({:key, {"Q", :press, _}}, _context, %{super: true} = state) do
    {:stop, :normal, state}
  end

  # Handles everything else
  def do_handle_input(_input, _context, state) do
    {:noreply, state}
  end

  @impl true
  # Save file on close
  def terminate(:shutdown, state) do
    save_state(state)
  end

  def terminate(reason, _state) do
    IO.inspect(reason)
  end

  # write state to file
  defp save_state(state) do
    File.write("state.bin", :erlang.term_to_binary(state))
  end

  # line ids
  defp drawn_line_id(cursor_coords) do
    Float.to_string(elem(cursor_coords, 0)) <>
      "," <> Float.to_string(elem(cursor_coords, 1))
  end

  defp add_line_to_group(%{graph: graph, stroke: stroke}, prev_coords, cursor_coords) do
    Graph.add_to(
      graph,
      @group_name,
      fn graph ->
        line(graph, {prev_coords, cursor_coords},
          stroke: stroke,
          id: drawn_line_id(cursor_coords)
        )
      end
    )
  end
end

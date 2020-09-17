defmodule DrawOMatic.Icons.Trash do
  use Scenic.Component, has_children: false
  import Scenic.Primitives

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Primitive

  @impl true
  def info(data) do
    """
    #{IO.ANSI.red()}ColorPicker color must be an atom
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  @impl true
  @doc false
  def verify({width, height} = data) when is_number(width) and is_number(height) do
    {:ok, data}
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------

  @impl true
  def init({width, height}, _opts) do
    Process.register(self(), :trash_scene)

    graph =
      Graph.build()
      |> group(
        fn g ->
          g
          |> rrect({width + 10, height + 10, 7},
            fill: :white,
            stroke: {1, :white},
            id: :trash_container
          )
          |> path(
            [
              :begin,
              # Handle
              {:move_to, width / 3.75, height / 12},
              {:line_to, width / 3.75, 0},
              {:line_to, width / 1.33, 0},
              {:line_to, width / 1.33, height / 12},
              # Top
              {:move_to, 0, height / 12},
              {:line_to, 0, height / 6},
              {:line_to, width, height / 6},
              {:line_to, width, height / 12},
              {:line_to, 0, height / 12}
            ],
            join: :round,
            cap: :round,
            stroke: {1.5, :black},
            t: {5, 5},
            pin: {0, 0},
            id: :trash_top
          )
          |> path(
            [
              # Bottom
              {:move_to, 0, height / 4},
              {:line_to, 0, height},
              {:line_to, width, height},
              {:line_to, width, height / 4},
              {:line_to, 0, height / 4},
              # Inside bottom lines
              {:move_to, width / 1.33, height / 2.75},
              {:line_to, width / 1.33, height / 1.15},
              {:move_to, width / 2, height / 2.75},
              {:line_to, width / 2, height / 1.15},
              {:move_to, width / 3.75, height / 2.75},
              {:line_to, width / 3.75, height / 1.15}
            ],
            join: :round,
            cap: :round,
            stroke: {1.5, :black},
            t: {5, 5},
            id: :trash_bottom
          )
        end,
        id: :trash
      )

    state = %{
      graph: graph,
      pressed: false,
      contained: false,
      id: :trash
    }

    {:ok, state, push: graph}
  end

  @impl true
  # --------------------------------------------------------
  def handle_input(
        {:cursor_enter, _uid},
        _context,
        %{
          pressed: true
        } = state
      ) do
    state = Map.put(state, :contained, true)
    {:noreply, state, push: update_color(state)}
  end

  def handle_input({:cursor_enter, _uid}, _context, state) do
    state = Map.put(state, :contained, true)
    {:noreply, state, push: update_color(state)}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_exit, _uid},
        _context,
        %{
          pressed: true
        } = state
      ) do
    state = Map.put(state, :contained, false)
    {:noreply, state, push: update_color(state)}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_exit, _uid},
        _context,
        state
      ) do
    state = Map.put(state, :contained, false)
    {:noreply, state, push: update_color(state)}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_button, {:left, :press, _, _}}, context, state) do
    state =
      state
      |> Map.put(:pressed, true)
      |> Map.put(:contained, true)

    update_color(state)

    ViewPort.capture_input(context, [:cursor_button, :cursor_pos])

    {:noreply, state, push: update_color(state)}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_button, {:left, :release, _, _}},
        context,
        %{pressed: pressed, contained: contained, id: id} = state
      ) do
    state = Map.put(state, :pressed, false)
    update_color(state)

    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    if pressed && contained do
      send_event({:click, id})
    end

    {:noreply, state, push: update_color(state)}
  end

  # --------------------------------------------------------
  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  # ============================================================================
  # internal utilities

  defp update_color(%{graph: graph, pressed: false, contained: false}) do
    Graph.modify(graph, :trash_container, fn p ->
      Primitive.put_style(p, :fill, :white)
    end)
  end

  defp update_color(%{graph: graph, pressed: false, contained: true}) do
    Graph.modify(graph, :trash_top, fn p ->
      Primitive.put_style(p, :rotate, 90)
    end)
  end

  defp update_color(%{graph: graph, pressed: true, contained: false}) do
    Graph.modify(graph, :trash_container, fn p ->
      Primitive.put_style(p, :fill, :white)
    end)
  end

  defp update_color(%{graph: graph, pressed: true, contained: true}) do
    Graph.modify(graph, :trash_container, fn p ->
      p
      |> Primitive.put_style(:fill, :light_grey)
      |> Primitive.put_style(:stroke, {1, :black})
    end)
  end
end

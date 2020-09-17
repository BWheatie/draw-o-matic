defmodule DrawOMatic.Icons.Eraser do
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
    Process.register(self(), :eraser_scene)

    graph =
      Graph.build()
      |> group(
        fn g ->
          g
          |> rect({width, height},
            stroke: {1, :white},
            id: :eraser_container,
            pin: {0, 0},
            rotate: 45
          )
          |> path(
            [
              :begin,
              # "bottom" or silver part
              {:move_to, 0, height / 2.5},
              {:line_to, 0, 0},
              {:line_to, width, 0},
              {:line_to, width, height / 2.5},
              {:line_to, 0, height / 2.5},
              # "grooves"
              {:move_to, width / 1.33, height / 7},
              {:line_to, width / 1.33, height / 3.5},
              {:move_to, width / 2, height / 7},
              {:line_to, width / 2, height / 3.5},
              {:move_to, width / 3.75, height / 7},
              {:line_to, width / 3.75, height / 3.5}
            ],
            join: :round,
            cap: :round,
            stroke: {1.5, :black},
            t: {0, 0},
            pin: {0, 0},
            rotate: 45,
            id: :eraser_bottom
          )
          |> path(
            [
              :begin,
              # "top" or the pink eraser part
              {:move_to, 0, height / 2.5},
              {:line_to, 0, height},
              {:line_to, width / 2, height},
              {:line_to, width, height / 1.5},
              {:line_to, width, height / 2.5}
            ],
            join: :round,
            cap: :round,
            stroke: {1.5, :black},
            t: {0, 0},
            pin: {0, 0},
            rotate: 45,
            id: :eraser_top
          )
        end,
        t: {0, -0},
        id: :eraser
      )

    state = %{
      graph: graph,
      pressed: false,
      contained: false,
      active: false,
      cursor_coords: nil,
      id: :eraser
    }

    {:ok, state, push: graph}
  end

  @impl true
  def filter_event({:pen, :active}, _, state) do
    state = %{state | active: false}
    {:noreply, state, push: update_color(state)}
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
      |> Map.put(:active, true)

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
    state = %{state | pressed: false}
    update_color(state)

    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    if pressed && contained do
      send_event({:click, id})
      Scenic.Scene.send_event(:pen_scene, {:eraser, :active})
    end

    {:noreply, state, push: update_color(state)}
  end

  # --------------------------------------------------------
  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  # ============================================================================
  # internal utilities

  defp update_color(%{graph: graph, pressed: false, contained: false, active: false}) do
    graph
    |> Graph.modify(:eraser_top, fn p ->
      Primitive.put_style(p, :fill, :white)
    end)
    |> Graph.modify(:eraser_bottom, fn p ->
      Primitive.put_style(p, :fill, :white)
    end)
  end

  defp update_color(%{graph: graph, pressed: false, contained: true}) do
    graph
    |> Graph.modify(:eraser_top, fn p ->
      Primitive.put_style(p, :fill, :pink)
    end)
    |> Graph.modify(:eraser_bottom, fn p ->
      Primitive.put_style(p, :fill, :silver)
    end)
  end

  defp update_color(%{graph: graph, active: true}) do
    graph
    |> Graph.modify(:eraser_top, fn p ->
      p
      |> Primitive.put_style(:fill, :pink)
      |> Primitive.put_style(:stroke, {2, :black})
    end)
    |> Graph.modify(:eraser_bottom, fn p ->
      p
      |> Primitive.put_style(:fill, :silver)
      |> Primitive.put_style(:stroke, {2, :black})
    end)
  end

  defp update_color(%{graph: graph, pressed: true, contained: true}) do
    graph
    |> Graph.modify(:eraser_top, fn p ->
      p
      |> Primitive.put_style(:fill, :pink)
      |> Primitive.put_style(:stroke, {2, :black})
    end)
    |> Graph.modify(:eraser_bottom, fn p ->
      p
      |> Primitive.put_style(:fill, :silver)
      |> Primitive.put_style(:stroke, {2, :black})
    end)
  end
end

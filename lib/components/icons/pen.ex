defmodule DrawOMatic.Icons.Pen do
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
  def verify({width, height} = data)
      when is_number(width) and is_number(height) do
    {:ok, data}
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------

  @impl true
  def init({width, height}, opts) do
    Process.register(self(), :pen_scene)

    graph =
      Graph.build()
      |> group(
        fn g ->
          g
          |> rrect({width + 10, height + 10, 7},
            fill: :white,
            stroke: {1, :white},
            id: :pen_container
          )
          |> path(
            [
              :begin,
              # {:move_to, width / 2, 0},
              # # draw the top most portion
              # # centering line
              # {:line_to, width / 2, height},
              {:move_to, 0, 0},
              {:line_to, 0, height / 1.77},
              {:line_to, width, height / 1.77},
              {:line_to, width, 0}
            ],
            join: :round,
            cap: :round,
            stroke: {1.5, :black},
            t: {5, 5},
            id: :pen_bottom
          )
          |> path(
            [
              :begin,
              {:move_to, 0, height / 1.77},
              {:line_to, width / 3.53, height / 1.15},
              {:line_to, width / 1.43, height / 1.15},
              {:line_to, width, height / 1.77}
            ],
            join: :round,
            cap: :round,
            stroke: {1.5, :black},
            t: {5, 5},
            id: :pen_top
          )
          |> path(
            [
              :begin,
              {:move_to, width / 3.05, height / 1.15},
              {:line_to, width / 2, height},
              {:line_to, width / 1.55, height / 1.15}
            ],
            join: :round,
            cap: :round,
            fill: opts[:styles].fill,
            stroke: {1.5, :black},
            t: {5, 5},
            id: :pen_tip
          )
        end,
        t: {0, -0},
        id: :pen_tip
      )

    state = %{
      graph: graph,
      pressed: false,
      contained: false,
      active: true,
      fill: opts[:styles].fill,
      id: :pen
    }

    {:ok, state, push: update_color(state)}
  end

  @impl true
  def filter_event({:eraser, :active}, _, state) do
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
      Scenic.Scene.send_event(:eraser_scene, {:pen, :active})
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
    Graph.modify(graph, :pen_container, fn p ->
      Primitive.put_style(p, :fill, :white)
    end)
  end

  defp update_color(%{graph: graph, pressed: false, contained: true}) do
    Graph.modify(graph, :pen_top, fn p ->
      Primitive.put_style(p, :fill, :silver)
    end)
  end

  defp update_color(%{graph: graph, active: true}) do
    graph
    |> Graph.modify(:pen_top, fn p ->
      p
      |> Primitive.put_style(:fill, :silver)
      |> Primitive.put_style(:stroke, {2.5, :black})
    end)
    |> Graph.modify(:pen_bottom, fn p ->
      Primitive.put_style(p, :stroke, {2.5, :black})
    end)
  end

  defp update_color(%{graph: graph, pressed: true, contained: true}) do
    graph
    |> Graph.modify(:pen_top, fn p ->
      p
      |> Primitive.put_style(:fill, :silver)
      |> Primitive.put_style(:stroke, {2.5, :black})
    end)
    |> Graph.modify(:pen_bottom, fn p ->
      Primitive.put_style(p, :stroke, {2.5, :black})
    end)
  end
end

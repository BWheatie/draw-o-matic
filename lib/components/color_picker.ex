defmodule DrawOMatic.Component.Input.ColorPicker do
  @moduledoc """
  Add a color_picker to a graph.
  ## Data
  `{radius, id}`
  `{radius, id, selected?}`
  * `radius` - an integer determining the size of the picker
  * `id` - any term. Identifies the color_picker.
  * `selected?` - boolean. `true` if selected. `false if not`. Default is `false` if
  this term is not provided.
  ## Usage
  The ColorPicker component is used by the RadioGroup component and usually isn't accessed
  directly, although you are free to do so if it fits your needs. There is no short-cut
  helper function so you will need to add it to the graph manually.
  The following example adds a caret to a graph.
      graph
      |> ColorPicker.add_to_graph({"A button", :an_id, true})
  """

  use Scenic.Component, has_children: false
  import Scenic.Primitives, only: [{:circle, 3}]

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort

  # --------------------------------------------------------
  @doc false
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
  def verify(color) when is_atom(color) do
    {:ok, color}
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------

  @impl true
  def init(color, opts) do
    Process.register(self(), color)
    styles = opts[:styles]
    id = opts[:id]

    stroke = Map.get(styles, :stroke, {1, :black})

    graph =
      Graph.build()
      |> circle(15, fill: color, stroke: stroke, id: id)

    state =
      if color == :black do
        %{
          graph: graph,
          pressed: false,
          contained: false,
          checked: true,
          id: id
        }
      else
        %{
          graph: graph,
          pressed: false,
          contained: false,
          checked: false,
          id: id
        }
      end

    {:ok, state, push: update_graph(state)}
  end

  @impl true
  def filter_event({_id, :inactive}, _, state) do
    state = %{state | checked: false}
    {:noreply, state, push: update_graph(state)}
  end

  # --------------------------------------------------------
  @doc false
  @impl true
  def handle_cast({:set_to_msg, set_id}, %{id: id} = state) do
    state = Map.put(state, :checked, set_id == id)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}, push: graph}
  end

  # --------------------------------------------------------
  @impl true
  def handle_input({:cursor_enter, _uid}, _, %{pressed: true} = state) do
    state = Map.put(state, :contained, true)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}, push: graph}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_exit, _uid}, _, %{pressed: true} = state) do
    state = Map.put(state, :contained, false)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}, push: graph}
  end

  # --------------------------------------------------------
  @doc false
  def handle_input({:cursor_button, {:left, :press, _, _}}, context, state) do
    state =
      state
      |> Map.put(:pressed, true)
      |> Map.put(:contained, true)

    graph = update_graph(state)

    ViewPort.capture_input(context, [:cursor_button, :cursor_pos])

    {:noreply, %{state | graph: graph}, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_button, {:left, :release, _, _}},
        context,
        %{contained: contained, id: id, pressed: pressed} = state
      ) do
    state = Map.put(state, :pressed, false)

    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    # only do the action if the cursor is still contained in the target
    if pressed && contained do
      send_event({:click, id})
    end

    graph = update_graph(state)

    {:noreply, %{state | graph: graph}, push: graph}
  end

  # --------------------------------------------------------
  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  defp update_graph(%{
         graph: graph,
         pressed: false,
         contained: false,
         checked: true,
         id: id
       }) do
    Graph.modify(graph, id, fn g ->
      Primitive.put_style(g, :stroke, {3, :black})
    end)
  end

  defp update_graph(%{
         graph: graph,
         pressed: false,
         contained: true,
         checked: true,
         id: id
       }) do
    Graph.modify(graph, id, fn g ->
      Primitive.put_style(g, :stroke, {3, :black})
    end)
  end

  defp update_graph(%{
         graph: graph,
         pressed: true,
         contained: true,
         checked: false,
         id: id
       }) do
    Graph.modify(graph, id, fn g ->
      Primitive.put_style(g, :stroke, {3, :black})
    end)
  end

  defp update_graph(%{
         graph: graph,
         pressed: false,
         contained: false,
         checked: false,
         id: id
       }) do
    Graph.modify(graph, id, fn g ->
      Primitive.put_style(g, :stroke, {1, :black})
    end)
  end

  defp update_graph(%{
         graph: graph,
         pressed: false,
         contained: true,
         checked: false,
         id: id
       }) do
    Graph.modify(graph, id, fn g ->
      Primitive.put_style(g, :stroke, {1, :black})
    end)
  end

  defp update_graph(%{
         graph: graph,
         pressed: true,
         contained: false,
         checked: true,
         id: id
       }) do
    Graph.modify(graph, id, fn g ->
      Primitive.put_style(g, :stroke, {3, :black})
    end)
  end
end

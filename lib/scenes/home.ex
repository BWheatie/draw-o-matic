defmodule DrawOMatic.Scene.Home do
  use Scenic.Scene

  import Scenic.Primitives
  import Scenic.Components

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias DrawOMatic.Component.Input.ColorPickerGroup
  alias DrawOMatic.Icons.Eraser
  alias DrawOMatic.Icons.Trash
  alias DrawOMatic.Icons.Pen

  require Logger

  @group_name :drawn_group_id
  @default_colors [:black, :white, :red, :orange, :yellow, :green, :blue, :indigo, :violet]

  defmodule State do
    defstruct [
      :graph,
      :drawing,
      :viewport,
      :draw_prev_coords,
      :stroke,
      :super,
      :alt,
      :saving,
      :saved,
      :erasing,
      :eraser_active,
      :timer,
      :viewport_pid
    ]
  end

  @impl true
  # Init the things. Builds a graph with white background and adds a rect the size of the viewport to capture inputs.
  # Also adds a button to clear the graph
  def init(_, opts) do
    Process.flag(:trap_exit, true)

    state =
      case File.read("state.bin") do
        {:ok, state} ->
          :erlang.binary_to_term(state)

        {:error, _} ->
          {:ok, %ViewPort.Status{size: {viewport_x, _} = viewport_size} = viewport} =
            ViewPort.info(opts[:viewport])

          color_picker_t = viewport_x / 3
          erase_t = viewport_x / 2

          graph =
            Graph.build(theme: :light)
            |> rect(viewport_size)
            |> ColorPickerGroup.add_to_graph(@default_colors,
              t: {color_picker_t, 0}
            )
            |> Eraser.add_to_graph({30, 70},
              id: :eraser,
              t: {erase_t, 2}
            )
            |> Trash.add_to_graph({15, 30},
              id: :trash,
              t: {viewport_x / 12, 2}
            )
            |> Pen.add_to_graph({20, 60},
              t: {erase_t + 60, 0},
              id: :pen,
              fill: :black
            )

          %State{
            graph: graph,
            viewport: viewport,
            stroke: {2, :black},
            viewport_pid: opts[:viewport],
            erasing: false,
            eraser_active: false
          }
      end

    {:ok, state, push: state.graph}
  end

  @impl true
  # event to update text in save prompt and append to existing string
  def filter_event({:value_changed, :save_prompt, value} = event, _, state) do
    [%{data: {_, current_val}}] = Graph.get(state.graph, :save_prompt)

    graph =
      state.graph
      |> Graph.modify(:save_prompt, fn p ->
        text_field(p, current_val <> value)
      end)

    state = %State{state | graph: graph, saving: true}
    {:cont, event, state}
  end

  # event to clear graph
  def filter_event({:click, :trash}, _, state) do
    graph = Graph.delete(state.graph, @group_name)

    state = %State{state | graph: graph, draw_prev_coords: nil}
    {:noreply, state, push: graph}
  end

  # event to activate eraser
  def filter_event({:click, :eraser}, _, state) do
    state = %State{state | drawing: false, eraser_active: true}
    {:noreply, state}
  end

  # event to activate pen(drawing)
  def filter_event({:click, :pen}, _, state) do
    graph = Graph.delete(state.graph, :eraser_circle)
    state = %State{state | graph: graph, eraser_active: false, erasing: false}
    {:noreply, state, push: graph}
  end

  # event for dismissing save toast
  def filter_event({:click, :save_toast}, _, state) do
    :timer.cancel(state.timer)
    graph = Graph.delete(state.graph, :save_toast)
    state = %State{state | graph: graph, timer: nil}
    {:noreply, state, push: graph}
  end

  # event to change get color picker value change
  def filter_event(
        {:value_changed, :color_picker, new_color},
        _context,
        %{stroke: {size, _}} = state
      ) do
    graph =
      Graph.modify(state.graph, :pen, fn p ->
        Primitive.put_style(p, :fill, new_color)
      end)

    state = %State{state | graph: graph, stroke: {size, new_color}}
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

  # ---------------------- Mouse inputs ------------------------
  @impl true
  # Handles drawing initial line
  def handle_input(
        {:cursor_button, {:left, :press, _, cursor_coords}},
        _context,
        %{erasing: false, eraser_active: false} = state
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
        draw_prev_coords: cursor_coords,
        erasing: false
    }

    {:noreply, state, push: graph}
  end

  # Handles drawing from previous point to current point
  def handle_input({:cursor_pos, cursor_coords}, _context, %{drawing: true} = state) do
    draw_prev_coords = Map.get(state, :draw_prev_coords)

    graph = add_line_to_group(state, draw_prev_coords, cursor_coords)

    state = %State{state | graph: graph, draw_prev_coords: cursor_coords}

    {:noreply, state, push: graph}
  end

  # Stop drawing
  def handle_input(
        {:cursor_button, {:left, :release, _, _cursor_coords}},
        _context,
        %{drawing: true} = state
      ) do
    state = %State{state | drawing: false}

    {:noreply, state}
  end

  # Stop drawing/ erasing when exiting the viewport
  def handle_input(
        {:viewport_exit, _},
        _context,
        state
      ) do
    state = %State{state | drawing: false, erasing: false}

    {:noreply, state}
  end

  # Render the eraser circle or move it
  def handle_input(
        {:cursor_pos, cursor_coords},
        _context,
        %{eraser_active: true, erasing: false} = state
      ) do
    graph =
      case Graph.get(state.graph, :eraser_circle) do
        [_ | _] ->
          Graph.modify(state.graph, :eraser_circle, fn p ->
            Primitive.put_transform(p, :translate, cursor_coords)
          end)

        _ ->
          circle(state.graph, 10, t: cursor_coords, id: :eraser_circle, stroke: {1, :black})
      end

    state = %State{state | graph: graph}
    {:noreply, state, push: graph}
  end

  # Start erasing
  def handle_input(
        {:cursor_button, {:left, :press, _, cursor_coords}},
        _context,
        %{eraser_active: true, erasing: false} = state
      ) do
    graph = circle(state.graph, 10, t: cursor_coords, fill: :white)
    state = %State{state | graph: graph, erasing: true}
    {:noreply, state, push: graph}
  end

  # Continue erasing until released
  def handle_input(
        {:cursor_pos, cursor_coords},
        _context,
        %{eraser_active: true, erasing: true} = state
      ) do
    graph = circle(state.graph, 10, t: cursor_coords, fill: :white)
    state = %State{state | graph: graph}
    {:noreply, state, push: graph}
  end

  # Stop erasing
  def handle_input(
        {:cursor_button, {:left, :release, _, _}},
        _context,
        %{eraser_active: true, erasing: true} = state
      ) do
    state = %State{state | erasing: false}
    {:noreply, state}
  end

  # ---------------------- Key inputs ------------------------

  # Handles super key input used for hot keys
  def handle_input({:key, {key, :press, _}}, _context, state)
      when key in ["left_super", "right_super"] do
    state = %State{state | super: true}
    {:noreply, state}
  end

  # Handles super key release
  def handle_input({:key, {key, :release, _}}, _context, state)
      when key in ["left_super", "right_super"] do
    state = %State{state | super: false}
    {:noreply, state}
  end

  # Handles alt key input used for hot keys
  def handle_input({:key, {key, :press, _}}, _context, state)
      when key in ["left_alt", "right_alt"] do
    state = %State{state | alt: true}
    {:noreply, state}
  end

  # Handles alt key release
  def handle_input({:key, {key, :release, _}}, _context, state)
      when key in ["left_alt", "right_alt"] do
    state = %State{state | alt: false}
    {:noreply, state}
  end

  # After triggering save, save the state with the file name
  def handle_input({:key, {"enter", :release, _}}, _context, %{saving: true} = state) do
    %{data: {_, file_name}} = Graph.get!(state.graph, :save_prompt)

    state =
      case File.stat(file_name) do
        {:ok, _} ->
          graph =
            state.graph
            |> button("A file already exists with that name. Please choose another name.",
              theme: :error,
              id: :save_toast
            )

          %State{state | graph: graph, saving: false}

        {:error, _} ->
          save_state(state, file_name)
          graph = state.graph |> button("File Saved", theme: :success, id: :save_toast)
          timer = Process.send_after(self(), :remove_save_toast, 3_500)
          %State{state | graph: graph, timer: timer}
      end

    {:noreply, state}
  end

  # Handles 's' key input to save state
  # Ideally figure out how to tell the viewport to change title with the file name.
  # Right now, if the file exists, it will not save since there is a file already.
  def handle_input({:key, {"S", :press, _}}, _context, %{super: true} = state) do
    graph =
      state.graph
      |> text_field("", hint: "File Name", id: :save_prompt, theme: :light, t: {100, 100})

    %State{state | graph: graph}

    {:noreply, state, push: state.graph}
  end

  # Handles quitting app
  def handle_input({:key, {"Q", :press, _}}, _context, %{super: true} = state) do
    {:stop, :normal, state}
  end

  # Handles everything else
  def handle_input(_input, _context, state) do
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
  defp save_state(state, file_name \\ "Untitled") do
    File.write(file_name <> ".bin", :erlang.term_to_binary(state))
  end

  # line ids
  defp drawn_line_id(cursor_coords) do
    Float.to_string(elem(cursor_coords, 0)) <>
      ", " <> Float.to_string(elem(cursor_coords, 1))
  end

  defp add_line_to_group(%{graph: graph, stroke: stroke}, draw_prev_coords, cursor_coords) do
    Graph.add_to(
      graph,
      @group_name,
      fn graph ->
        line(graph, {draw_prev_coords, cursor_coords},
          stroke: stroke,
          id: drawn_line_id(cursor_coords)
        )
      end
    )
  end
end

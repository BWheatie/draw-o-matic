defmodule DrawOMatic.CustomComponents do
  alias Scenic.Graph
  alias Scenic.Primitive

  @doc """
  Add a Color Picker to a graph
  ### Data
  `radius`
  * `radius` - an Integer as the radius of the color picker
  * `checked?` - must be a boolean and indicates if the button is selected.
  `checked?` is not required and will default to `false` if not supplied.
  ### Messages
  When the state of the radio group changes, it sends an event message to the
  host scene in the form of:
  `{:value_changed, id}`
  ### Styles
  Radio Buttons honor the following styles
  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`
  ### Theme
  Radio buttons work well with the following predefined themes: `:light`,
  `:dark`
  To pass in a custom theme, supply a map with at least the following entries:
  * `:text` - the color of the text
  * `:background` - the background of the component
  * `:border` - the border of the component
  * `:active` - the background of the circle while the button is pressed
  * `:thumb` - the color of inner selected-mark
  ### Examples
  The following example creates a radio group and positions it on the screen.
      graph
      |> color_picker([
          {"Radio A", :radio_a},
          {"Radio B", :radio_b, true},
          {"Radio C", :radio_c},
        ], id: :color_picker_id, translate: {20, 20})
  """
  @spec color_picker(
          source :: Graph.t() | Primitive.t(),
          data :: {radius :: Integer.t(), colors :: list()},
          options :: list
        ) :: Graph.t() | Primitive.t()
  def color_picker(graph, data, options \\ [])

  def color_picker(%Graph{} = g, data, options) do
    add_to_graph(g, Component.Input.ColorPicker, data, options)
  end

  def color_picker(%Primitive{module: SceneRef} = p, data, options) do
    modify(p, Component.Input.ColorPicker, data, options)
  end

  @doc """
  Generate an uninstantiated color_picker spec, parallel to the concept of
  primitive specs. See `Components.color_picker` for data and options values.
  """
  def color_picker_spec(data, options), do: &color_picker(&1, data, options)

  defp add_to_graph(%Graph{} = g, mod, data, options) do
    mod.verify!(data)
    mod.add_to_graph(g, data, options)
  end

  defp modify(%Primitive{module: SceneRef} = p, mod, data, options) do
    mod.verify!(data)
    Primitive.put(p, {mod, data}, options)
  end
end

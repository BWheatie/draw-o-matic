# defmodule DrawOMatic.Component.SavePrompt do
#   use Scenic.Scene
#   alias Scenic.Graph
#   import Scenic.Components

#   def info(data) do
#     """
#       #{IO.ANSI.red()}#{__MODULE__} data must contain a string
#       #{IO.ANSI.yellow()}Received: #{inspect(data)}
#       #{IO.ANSI.default_color()}
#     """
#   end

#   def verify(data) when is_binary(data) do
#     {:ok, data}
#   end

#   def verify(_), do: :invalid_data

#   @impl true
#   def init(string, _opts) do
# would like a rrect that containing the text_field, list of saved files
#     graph =
#       Graph.build(clear_color: :white)
#       |> text_field("", hint: string, id: :text_field, theme: :light)

#     {:ok, graph, push: graph}
#   end

#   @impl true
#   def filter_event({:value_changed, :text_field, value} = event, _, state) do
#     graph =
#       state
#       |> Graph.get!(:text_field)
#       |> text_field(value)

#     {:cont, event, graph}
#   end
# end

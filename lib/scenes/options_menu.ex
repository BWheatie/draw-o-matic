# Would like to research how to access platform specific styled components

# defmodule DrawOMatic.Scene.OptionsMenu do
#   use Scenic.Scene

#   alias Scenic.Graph
#   alias Scenic.ViewPort

#   import Scenic.Primitives

#   defmodule State do
#     defstruct [
#       :graph,
#       :viewport
#     ]
#   end

#     def info(data) do
#     """
#       #{IO.ANSI.red()}#{__MODULE__} data must be a list of menu options
#       #{IO.ANSI.yellow()}Received: #{inspect(data)}
#       #{IO.ANSI.default_color()}
#     """
#   end

#   def verify(data) when is_list(data) do
#     {:ok, data}
#   end

#   def verify(_), do: :invalid_data

#   def init(menu_options, opts) do
#     graph =
#       Graph.build(clear_color: :dark_grey)
#       |>

#     {:ok, graph, push: graph}
#   end
# end

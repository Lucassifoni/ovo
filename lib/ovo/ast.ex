defmodule Ovo.Ast do
  @moduledoc """

  """
  defstruct [:kind, :nodes, :value]

  def make(), do: %__MODULE__{kind: :root, nodes: [], value: nil}
end
